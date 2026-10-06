import 'package:cuycash/feature/security/application/security_actions.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/devices/bloc/linked_devices_bloc.dart';
import 'package:cuycash/presentation/profile/devices/linked_devices_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecurityState estado;

  Future<void> abrir(WidgetTester tester) async {
    estado = MemorySecurityState.demo(clock: DateTime.now);
    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => LinkedDevicesBloc(
            SecurityActions(
              MemorySecurityRepository(estado, clock: DateTime.now),
            ),
          )..add(const LinkedDevicesEvent.started()),
          child: const LinkedDevicesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista con "Este teléfono" y sin desvincular en esa fila', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.text('Este teléfono'), findsOneWidget);
    expect(find.text('iPhone14,5'), findsOneWidget);
    expect(find.text('Desvincular'), findsOneWidget);
  });

  testWidgets('desvincular pide confirmación, quita la fila y avisa', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.text('Desvincular'));
    await tester.pumpAndSettle();
    expect(find.text('¿Desvincular este dispositivo?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Desvincular'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('iPhone14,5'), findsNothing);
    expect(
      find.text('Listo, ese dispositivo ya no tiene acceso.'),
      findsOneWidget,
    );
  });

  testWidgets('si otro teléfono ya lo había sacado, también es éxito', (
    tester,
  ) async {
    await abrir(tester);
    estado.devices.removeWhere((d) => !d.esEste);

    await tester.tap(find.text('Desvincular'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Desvincular'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Listo, ese dispositivo ya no tiene acceso.'),
      findsOneWidget,
    );
    expect(find.text('iPhone14,5'), findsNothing);
  });
}
