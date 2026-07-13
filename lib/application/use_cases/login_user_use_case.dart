import '../models/auth_session.dart';
import '../ports/i_auth_api_client.dart';
import '../ports/i_token_storage.dart';

/// Caso de uso: iniciar sesión con credenciales y persistir el JWT localmente.
class LoginUserUseCase {
  /// Crea el caso de uso con [authApiClient] y [tokenStorage].
  const LoginUserUseCase({
    required IAuthApiClient authApiClient,
    required ITokenStorage tokenStorage,
  })  : _authApiClient = authApiClient,
        _tokenStorage = tokenStorage;

  final IAuthApiClient _authApiClient;
  final ITokenStorage _tokenStorage;

  /// Autentica [username]/[password] y guarda la sesión resultante.
  Future<AuthSession> execute({
    required String username,
    required String password,
  }) async {
    final session = await _authApiClient.login(username: username, password: password);
    await _tokenStorage.saveSession(session);
    return session;
  }
}
