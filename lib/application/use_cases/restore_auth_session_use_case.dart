import '../models/auth_session.dart';
import '../ports/i_token_storage.dart';

/// Caso de uso: restaurar la sesión guardada al arrancar la aplicación.
class RestoreAuthSessionUseCase {
  /// Crea el caso de uso con el [tokenStorage] donde leer la sesión.
  const RestoreAuthSessionUseCase({required ITokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  final ITokenStorage _tokenStorage;

  /// Lee la sesión persistida; devuelve `null` si el usuario no estaba logueado.
  Future<AuthSession?> execute() async {
    return _tokenStorage.readSession();
  }
}
