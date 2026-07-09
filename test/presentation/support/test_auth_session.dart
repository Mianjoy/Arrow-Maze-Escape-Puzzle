import 'package:arrow_maze_escape_puzzle/application/models/auth_session.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/login_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/logout_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/register_user_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/restore_auth_session_use_case.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/auth/in_memory_token_storage.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/auth_api_client.dart';
import 'package:arrow_maze_escape_puzzle/presentation/auth/auth_session_controller.dart';
import 'package:http/http.dart' as http;

import '../../support/mock_http_client.dart';

/// Construye un [AuthSessionController] con sesión precargada para widget tests.
AuthSessionController buildTestAuthSessionController({
  AuthSession? session,
}) {
  final storage = InMemoryTokenStorage();
  const config = ApiConfig(baseUrl: 'http://widget-test');
  final authClient = AuthApiClient(
    config: config,
    httpClient: MockHttpClient((_) async => http.Response('{}', 500)),
  );

  return AuthSessionController(
    loginUserUseCase: LoginUserUseCase(authApiClient: authClient, tokenStorage: storage),
    registerUserUseCase: RegisterUserUseCase(authApiClient: authClient, tokenStorage: storage),
    logoutUserUseCase: LogoutUserUseCase(tokenStorage: storage),
    restoreAuthSessionUseCase: RestoreAuthSessionUseCase(tokenStorage: storage),
    initialSession: session ??
        const AuthSession(
          token: 'test-token',
          userId: 'test-user',
          username: 'tester',
        ),
  );
}
