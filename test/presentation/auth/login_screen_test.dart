import 'package:arrow_maze_escape_puzzle/application/use_cases/login_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/logout_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/register_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/restore_auth_session_use_case.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/auth/in_memory_token_storage.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/auth_api_client.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/auth/auth_session_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/auth/login_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/mock_http_client.dart';

/// Regresión: un submit fallido de login debe reflejarse en pantalla sin
/// necesitar ninguna otra interacción — cubre el bug donde `LoginController`
/// no reenviaba las notificaciones de `AuthSessionController`, dejando el
/// error calculado pero invisible en la UI.
void main() {
  testWidgets('should_show_invalid_credentials_message_when_login_fails_with_401', (tester) async {
    // Arrange
    final storage = InMemoryTokenStorage();
    const config = ApiConfig(baseUrl: 'http://widget-test');
    final authClient = AuthApiClient(
      config: config,
      httpClient: MockHttpClient(
        (_) async => http.Response(
          '{"error":{"message":"Invalid username or password"}}',
          401,
        ),
      ),
    );

    final authSessionController = AuthSessionController(
      loginUserUseCase: LoginUserUseCase(authApiClient: authClient, tokenStorage: storage),
      registerUserUseCase: RegisterUserUseCase(authApiClient: authClient, tokenStorage: storage),
      logoutUserUseCase: LogoutUserUseCase(tokenStorage: storage),
      restoreAuthSessionUseCase: RestoreAuthSessionUseCase(tokenStorage: storage),
    );

    final controller = LoginController(authSessionController: authSessionController);

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(home: LoginScreen(controller: controller)),
      ),
    );

    // Act
    await tester.enterText(find.byKey(const ValueKey('login-username')), 'someuser');
    await tester.enterText(find.byKey(const ValueKey('login-password')), 'wrong-password');
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text(const AppStringsEs().invalidCredentialsError), findsOneWidget);
  });

  testWidgets('should_show_english_labels_when_locale_is_english', (tester) async {
    final storage = InMemoryTokenStorage();
    const config = ApiConfig(baseUrl: 'http://widget-test');
    final authClient = AuthApiClient(config: config, httpClient: MockHttpClient((_) async {
      throw StateError('unused in this test');
    }));

    final authSessionController = AuthSessionController(
      loginUserUseCase: LoginUserUseCase(authApiClient: authClient, tokenStorage: storage),
      registerUserUseCase: RegisterUserUseCase(authApiClient: authClient, tokenStorage: storage),
      logoutUserUseCase: LogoutUserUseCase(tokenStorage: storage),
      restoreAuthSessionUseCase: RestoreAuthSessionUseCase(tokenStorage: storage),
    );

    final controller = LoginController(authSessionController: authSessionController);

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEn(),
        child: MaterialApp(home: LoginScreen(controller: controller)),
      ),
    );

    expect(find.text(const AppStringsEn().loginTitle), findsOneWidget);
    expect(find.text(const AppStringsEn().signIn), findsOneWidget);
    expect(find.text(const AppStringsEn().createAccount), findsOneWidget);
  });

  testWidgets('should_show_spanish_labels_when_locale_is_spanish', (tester) async {
    final storage = InMemoryTokenStorage();
    const config = ApiConfig(baseUrl: 'http://widget-test');
    final authClient = AuthApiClient(config: config, httpClient: MockHttpClient((_) async {
      throw StateError('unused in this test');
    }));

    final authSessionController = AuthSessionController(
      loginUserUseCase: LoginUserUseCase(authApiClient: authClient, tokenStorage: storage),
      registerUserUseCase: RegisterUserUseCase(authApiClient: authClient, tokenStorage: storage),
      logoutUserUseCase: LogoutUserUseCase(tokenStorage: storage),
      restoreAuthSessionUseCase: RestoreAuthSessionUseCase(tokenStorage: storage),
    );

    final controller = LoginController(authSessionController: authSessionController);

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(home: LoginScreen(controller: controller)),
      ),
    );

    expect(find.text(const AppStringsEs().loginTitle), findsOneWidget);
    expect(find.text(const AppStringsEs().signIn), findsOneWidget);
    expect(find.text(const AppStringsEs().createAccount), findsOneWidget);
  });
}
