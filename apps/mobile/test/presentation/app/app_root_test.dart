import 'package:cuycash/core/injection/envs/mock_dependencies.dart';
import 'package:cuycash/presentation/app/app_root.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  // Los asserts de `provider` solo saltan en debug y al montar la raíz: sin
  // este test, un error así no aparece hasta correr la app.
  testWidgets('la composición raíz se monta sin errores', (tester) async {
    final dependencies = await tester.runAsync(buildMockDependencies);

    await tester.pumpWidget(AppRoot(dependencies: dependencies!));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppRoot), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
