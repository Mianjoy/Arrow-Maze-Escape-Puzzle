import 'package:arrow_maze_escape_puzzle/application/use_cases/login_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/logout_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/register_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/restore_auth_session_use_case.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/auth/in_memory_token_storage.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/auth_api_client.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/auth/auth_session_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_auth_session.dart';

/// Controlador de sesión sin usuario autenticado (a diferencia de
/// `buildTestAuthSessionController`, que siempre precarga una sesión).
AuthSessionController _buildUnauthenticatedController() {
  final storage = InMemoryTokenStorage();
  const config = ApiConfig(baseUrl: 'http://widget-test');
  final authClient = AuthApiClient(config: config);

  return AuthSessionController(
    loginUserUseCase: LoginUserUseCase(authApiClient: authClient, tokenStorage: storage),
    registerUserUseCase: RegisterUserUseCase(authApiClient: authClient, tokenStorage: storage),
    logoutUserUseCase: LogoutUserUseCase(tokenStorage: storage),
    restoreAuthSessionUseCase: RestoreAuthSessionUseCase(tokenStorage: storage),
  );
}

void main() {
  testWidgets('should_navigate_to_levels_when_authenticated_and_play_is_tapped', (tester) async {
    // Arrange: session pre-loaded (see test_auth_session.dart default).
    final authSessionController = buildTestAuthSessionController();
    String? pushedRoute;

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(
          home: HomeScreen(authSessionController: authSessionController),
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            return MaterialPageRoute(builder: (_) => const SizedBox());
          },
        ),
      ),
    );

    // Act
    await tester.tap(find.byKey(const ValueKey('home-play')));
    await tester.pumpAndSettle();

    // Assert
    expect(pushedRoute, '/levels');
  });

  testWidgets('should_navigate_to_login_when_not_authenticated_and_play_is_tapped', (tester) async {
    // Arrange: no session at all.
    final authSessionController = _buildUnauthenticatedController();
    String? pushedRoute;

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(
          home: HomeScreen(authSessionController: authSessionController),
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            return MaterialPageRoute(builder: (_) => const SizedBox());
          },
        ),
      ),
    );

    // Act
    await tester.tap(find.byKey(const ValueKey('home-play')));
    await tester.pumpAndSettle();

    // Assert
    expect(pushedRoute, '/login');
  });

  testWidgets('should_navigate_to_settings_when_settings_button_is_tapped', (tester) async {
    // Arrange
    final authSessionController = buildTestAuthSessionController();
    String? pushedRoute;

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(
          home: HomeScreen(authSessionController: authSessionController),
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            return MaterialPageRoute(builder: (_) => const SizedBox());
          },
        ),
      ),
    );

    // Act
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();

    // Assert
    expect(pushedRoute, '/settings');
  });
}
