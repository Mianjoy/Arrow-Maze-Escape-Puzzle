import '../../application/models/auth_session.dart';
import '../../application/ports/i_token_storage.dart';

/// Almacén de sesión en memoria para tests y entornos sin persistencia.
///
/// No sobrevive al reinicio de la app; útil en widget tests y E2E simulados.
class InMemoryTokenStorage implements ITokenStorage {
  AuthSession? _session;

  @override
  /// Guarda la [session] en una variable interna.
  Future<void> saveSession(AuthSession session) async {
    _session = session;
  }

  @override
  /// Devuelve la sesión guardada en memoria, o `null`.
  Future<AuthSession?> readSession() async => _session;

  @override
  /// Borra la sesión en memoria.
  Future<void> clearSession() async {
    _session = null;
  }
}
