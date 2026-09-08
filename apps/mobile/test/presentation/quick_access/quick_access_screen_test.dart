import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/quick_access/bloc/quick_access_bloc.dart';
import 'package:cuycash/presentation/quick_access/quick_access_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = RememberedUser(dni: '12345678', fullName: 'Juan Pérez', alias: '@juan');

  testWidgets('saluda y el keypad llena los dots', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = QuickAccessBloc(
      auth: AuthActions(MemoryAuthRepository()),
      device: DeviceActions(MemoryDeviceStore()),
      user: user,
      clock: () => DateTime(2026),
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const QuickAccessScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Juan'), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(bloc.state.pin, '1');
  });
}
