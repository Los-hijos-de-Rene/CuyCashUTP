import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/presentation/app/app_redirect.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const authed = AuthState.authenticated(
      AuthSession(userId: 'u', identifier: '12345678'));
  const unauthed = AuthState.unauthenticated();

  test('no autenticado fuera de gate → /onboarding', () {
    expect(appRedirect(unauthed, AppRoutes.home), AppRoutes.onboarding);
  });

  test('no autenticado ya en /login → sin redirect', () {
    expect(appRedirect(unauthed, AppRoutes.login), isNull);
  });

  test('autenticado en pantalla de gate → /home', () {
    expect(appRedirect(authed, AppRoutes.login), AppRoutes.home);
    expect(appRedirect(authed, AppRoutes.onboarding), AppRoutes.home);
  });

  test('autenticado en /home → sin redirect', () {
    expect(appRedirect(authed, AppRoutes.home), isNull);
  });

  test('no autenticado en acceso rápido / bloqueado → sin redirect', () {
    expect(appRedirect(unauthed, AppRoutes.quickAccess), isNull);
    expect(appRedirect(unauthed, AppRoutes.blocked), isNull);
  });

  test('autenticado en acceso rápido → /home', () {
    expect(appRedirect(authed, AppRoutes.quickAccess), AppRoutes.home);
  });
}
