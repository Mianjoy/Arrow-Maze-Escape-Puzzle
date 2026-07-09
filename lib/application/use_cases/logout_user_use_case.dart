import '../ports/i_token_storage.dart';

/// Caso de uso: cerrar sesión eliminando el token persistido.
class LogoutUserUseCase {
  /// Crea el caso de uso con el [tokenStorage] a limpiar.
  const LogoutUserUseCase({required ITokenStorage tokenStorage}) : _tokenStorage = tokenStorage;

  final ITokenStorage _tokenStorage;

  /// Borra la sesión del almacenamiento local.
  Future<void> execute() async {
    await _tokenStorage.clearSession();
  }
}
