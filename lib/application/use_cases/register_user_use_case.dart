import '../models/auth_session.dart';
import '../ports/i_auth_api_client.dart';
import '../ports/i_token_storage.dart';

/// Caso de uso: registrar un nuevo usuario y persistir la sesión tras login.
///
/// El backend no devuelve JWT en el registro; este caso de uso registra
/// y luego inicia sesión automáticamente para dejar al usuario autenticado.
class RegisterUserUseCase {
  /// Crea el caso de uso con [authApiClient] y [tokenStorage].
  const RegisterUserUseCase({
    required IAuthApiClient authApiClient,
    required ITokenStorage tokenStorage,
  })  : _authApiClient = authApiClient,
        _tokenStorage = tokenStorage;

  final IAuthApiClient _authApiClient;
  final ITokenStorage _tokenStorage;

  /// Registra [username]/[password] y devuelve la sesión tras login automático.
  Future<AuthSession> execute({
    required String username,
    required String password,
  }) async {
    await _authApiClient.register(username: username, password: password);
    final session = await _authApiClient.login(username: username, password: password);
    await _tokenStorage.saveSession(session);
    return session;
  }
}
