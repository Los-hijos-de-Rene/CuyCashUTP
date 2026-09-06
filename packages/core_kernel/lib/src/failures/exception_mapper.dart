import 'dart:async';

import 'global_failure.dart';

/// Clasificación transportable de una excepción de infraestructura.
enum FailureKind { noConnection, timeout, permissionDenied, notFound, storage }

typedef Classified = ({FailureKind kind, String? detail});

/// Clasificador adicional registrado por una capa de infraestructura.
/// Devuelve null si no reconoce el error.
typedef FailureClassifier = Classified? Function(Object error);

/// El mapper ÚNICO de excepción → failure. core_kernel no depende de SDKs;
/// los clasificadores específicos se REGISTRAN desde el bootstrap de la app.
abstract final class ExceptionMapper {
  static final List<FailureClassifier> _classifiers = [];

  static void register(FailureClassifier classifier) =>
      _classifiers.add(classifier);

  /// Solo para tests.
  static void reset() => _classifiers.clear();

  static GlobalFailure<F> map<F>(Object error, StackTrace stackTrace) {
    if (error is TimeoutException) return GlobalFailure<F>.timeout();
    for (final classify in _classifiers) {
      final classified = classify(error);
      if (classified == null) continue;
      return switch (classified.kind) {
        FailureKind.noConnection => GlobalFailure<F>.noConnection(),
        FailureKind.timeout => GlobalFailure<F>.timeout(),
        FailureKind.permissionDenied =>
          GlobalFailure<F>.permissionDenied(classified.detail),
        FailureKind.notFound => GlobalFailure<F>.notFound(),
        FailureKind.storage => GlobalFailure<F>.storage(classified.detail ?? ''),
      };
    }
    return GlobalFailure<F>.unexpected(error, stackTrace);
  }
}
