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
/// [onUnauthenticated] se avisa solo ante un 401 de SESIÓN: el cuerpo trae
/// `code == 'UNAUTHENTICATED'` (el único que emite `deps.py` por token ausente,
/// vencido o revocado) y la petición llevaba token. Otros 401 del backend
/// (INVALID_CREDENTIALS, INVALID_TICKET de un OTP) son errores de negocio y no
/// deben cerrar una sesión abierta; el discriminante es el código, no el
/// estado HTTP.
Dio buildAuthenticatedDio({
  required String baseUrl,
  required String deviceId,
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
      headers: {'X-Device-Id': deviceId},
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
        if (response.statusCode == 401 &&
            response.requestOptions.extra[_tokenAttached] == true &&
            data is Map &&
            data['code'] == 'UNAUTHENTICATED') {
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
