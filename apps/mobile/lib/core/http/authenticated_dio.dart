import 'package:dio/dio.dart';

/// Marca, en `RequestOptions.extra`, las peticiones a las que el interceptor
/// adjuntó un token. Solo esas pueden provocar un aviso de sesión vencida.
const _tokenAttached = 'cuycash.tokenAttached';

/// El `Dio` que usan las features que hablan con el backend.
///
/// El token se adjunta en un interceptor y no en cada repositorio: así ningún
/// repositorio necesita saber qué es un token, y añadir una feature nueva no
/// es una oportunidad más de olvidarse de la cabecera.
///
/// [readToken] se lee en CADA petición, no una vez al construir: la sesión
/// cambia (login, logout) y un token capturado al armar el grafo quedaría
/// obsoleto.
///
/// [onUnauthenticated] se avisa ante un 401 que llevó token, salvo que el
/// cuerpo traiga un `code` legible distinto de `UNAUTHENTICATED`.
///
/// El backend propio SIEMPRE envía `code`: INVALID_CREDENTIALS o INVALID_TICKET
/// son errores de negocio y no cierran una sesión abierta. Pero un 401 con
/// token y SIN `code` legible (gateway, WAF, un `HTTPException` por defecto,
/// JSON servido como texto) no puede ser de negocio: es sesión o
/// infraestructura. El coste es asimétrico: un falso positivo cuesta volver a
/// entrar; un falso negativo deja al usuario dentro con una sesión muerta y
/// sin forma de llegar al login.
Dio buildAuthenticatedDio({
  required String baseUrl,
  required String deviceId,
  String? deviceName,
  required String? Function() readToken,
  required void Function() onUnauthenticated,
  Duration connectTimeout = const Duration(seconds: 20),
  Duration receiveTimeout = const Duration(seconds: 70),
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      // Las dos esperas son distintas a propósito. El plan gratuito del
      // hosting suspende el servicio tras unos minutos sin tráfico: la
      // primera petición conecta en el acto —responde el proxy— y después
      // se queda esperando a que el contenedor arranque, cerca de un
      // minuto. Con un único valor hay que elegir entre cortar ese
      // arranque en frío o tardar más de un minuto en avisar de que no hay
      // red. Separadas, se consigue lo uno y lo otro.
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        'X-Device-Id': deviceId,
        // Solo para mostrar en "Dispositivos vinculados"; nada de seguridad
        // depende de él.
        'X-Device-Name': ?deviceName,
      },
      // Los 4xx son respuestas de negocio (sin saldo, PIN errado), no
      // excepciones: se leen y se mapean a failures.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          options.extra[_tokenAttached] = true;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final data = response.data;
        final code = data is Map ? data['code'] : null;
        if (response.statusCode == 401 &&
            response.requestOptions.extra[_tokenAttached] == true &&
            (code == null || code == 'UNAUTHENTICATED')) {
          // No se reintenta ni se renueva en silencio. Si la sesión venció a
          // mitad de un envío, el usuario debe acabar en el login con la
          // operación SIN ejecutar: reintentar a ciegas podría cobrarle dos
          // veces. La respuesta sigue su curso para que el repositorio la mapee.
          onUnauthenticated();
        }
        handler.next(response);
      },
    ),
  );

  return dio;
}
