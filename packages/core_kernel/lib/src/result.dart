import 'package:fpdart/fpdart.dart';

import 'failures/global_failure.dart';

/// Typedefs de resultado: las firmas de los contratos de domain devuelven
/// estos tipos, nunca lanzan.
typedef Result<F, T> = Either<GlobalFailure<F>, T>;
typedef FutureResult<F, T> = Future<Result<F, T>>;
typedef StreamResult<F, T> = Stream<Result<F, T>>;
