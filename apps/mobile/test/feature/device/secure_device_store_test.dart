import 'package:cuycash/feature/device/infrastructure/secure_device_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Almacén que falla como el Keystore de Android cuando su clave se invalida
/// (p. ej. tras cambiar el bloqueo de pantalla): leer o borrar lanza.
class _AlmacenRoto extends FlutterSecureStorage {
  _AlmacenRoto({this.fallaLeer = false, this.fallaBorrar = const {}});

  final bool fallaLeer;
  final Set<String> fallaBorrar;
  final borradas = <String>[];

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (fallaLeer) throw Exception('keystore inválido');
    return null;
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (fallaBorrar.contains(key)) throw Exception('keystore inválido');
    borradas.add(key);
  }
}

void main() {
  test('leer la credencial con el almacén roto da null, no lanza', () async {
    final store = SecureDeviceStore(_AlmacenRoto(fallaLeer: true));

    expect(await store.readBiometricCredential(), isNull);
  });

  test(
    'clearUser borra la credencial aunque falle borrar el usuario',
    () async {
      final almacen = _AlmacenRoto(fallaBorrar: {'cuycash.remembered_user'});
      final store = SecureDeviceStore(almacen);

      await expectLater(store.clearUser(), throwsException);

      // Otro usuario en este teléfono no puede heredar la huella del anterior.
      expect(almacen.borradas, contains('cuycash.biometric_credential'));
    },
  );
}
