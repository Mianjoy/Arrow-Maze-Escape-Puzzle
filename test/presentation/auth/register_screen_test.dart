import 'package:arrow_maze_escape_puzzle/application/use_cases/login_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/logout_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/register_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/restore_auth_session_use_case.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/auth/in_memory_token_storage.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/auth_api_client.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/auth/auth_session_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/auth/register_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/mock_http_client.dart';

/// Regresión equivalente a `login_screen_test.dart` para el registro: un
/// submit fallido (409, usuario ya existe) debe mostrarse sin necesitar otra
/// interacción — antes `RegisterController` no reenviaba las notificaciones
/// de `AuthSessionController`.
void main() {
  testWidgets('should_show_username_taken_message_when_register_fails_with_409', (tester) async {
    // Arrange
    final storage = InMemoryTokenStorage();
    const config = ApiConfig(baseUrl: 'http://widget-test');
    final authClient = AuthApiClient(
      config: config,
      httpClient: MockHttpClient(
        (_) async => http.Response(
          '{"error":{"message":"A user with username \\"someuser\\" already exists"}}',
          409,
        ),
      ),
    );

    final authSessionController = AuthSessionController(
      loginUserUseCase: LoginUserUseCase(authApiClient: authClient, tokenStorage: storage),
      registerUserUseCase: RegisterUserUseCase(authApiClient: authClient, tokenStorage: storage),
      logoutUserUseCase: LogoutUserUseCase(tokenStorage: storage),
      restoreAuthSessionUseCase: RestoreAuthSessionUseCase(tokenStorage: storage),
    );

    final controller = RegisterController(authSessionController: authSessionController);

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(home: RegisterScreen(controller: controller)),
      ),
    );

    // Act
    await tester.enterText(find.byKey(const ValueKey('register-username')), 'someuser');
    await tester.enterText(find.byKey(const ValueKey('register-password')), 'super-secret');
    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text(const AppStringsEs().usernameAlreadyExistsError), findsOneWidget);
  });
}
