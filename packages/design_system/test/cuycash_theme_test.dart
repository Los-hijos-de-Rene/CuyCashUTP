import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light() usa los tokens de marca', () {
    final theme = CuyCashTheme.light();
    expect(theme.colorScheme.primary, CuyCashColors.primary);
    expect(theme.scaffoldBackgroundColor, CuyCashColors.surface);
    expect(theme.useMaterial3, isTrue);
  });

  test('botón primario tiene alto mínimo 52', () {
    final theme = CuyCashTheme.light();
    final size = theme.elevatedButtonTheme.style!.minimumSize!
        .resolve({});
    expect(size!.height, 52);
  });
}
