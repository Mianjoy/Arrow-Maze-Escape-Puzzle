import '../models/auth_session.dart';

/// Puerto de persistencia local del token de sesión (capa de aplicación).
///
/// Permite restaurar la sesión al reiniciar la app sin volver a pedir
/// credenciales al usuario.
abstract interface class ITokenStorage {
  /// Guarda la [session] en almacenamiento local seguro o en memoria.
  Future<void> saveSession(AuthSession session);

  /// Recupera la sesión persistida, o `null` si no hay token guardado.
  Future<AuthSession?> readSession();

  /// Elimina cualquier sesión almacenada (logout).
  Future<void> clearSession();
}
