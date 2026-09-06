import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart' hide Timeout;

void main() {
  setUp(ExceptionMapper.reset);
  tearDown(ExceptionMapper.reset);

  test('TimeoutException → Timeout sin clasificadores', () {
    final failure = ExceptionMapper.map<String>(
      TimeoutException('x'),
      StackTrace.current,
    );
    expect(failure, isA<Timeout<String>>());
  });

  test('error desconocido → Unexpected', () {
    final failure = ExceptionMapper.map<String>(
      StateError('boom'),
      StackTrace.current,
    );
    expect(failure, isA<Unexpected<String>>());
  });

  test('clasificador registrado mapea a su FailureKind', () {
    ExceptionMapper.register(
      (error) => error is FormatException
          ? (kind: FailureKind.permissionDenied, detail: 'rls')
          : null,
    );
    final failure = ExceptionMapper.map<String>(
      const FormatException(),
      StackTrace.current,
    );
    expect(failure, isA<PermissionDenied<String>>());
    expect((failure as PermissionDenied<String>).hint, 'rls');
  });
}
