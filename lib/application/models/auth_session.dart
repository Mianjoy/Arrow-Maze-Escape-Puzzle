import '../../domain/domain.dart';

/// Representa una sesión autenticada del jugador tras un login exitoso.
///
/// Contiene el JWT emitido por el backend y los datos públicos del usuario
/// necesarios para identificar partidas y sincronizar progreso.
class AuthSession {
  /// Crea una sesión con [token], [userId] y [username] del backend.
  const AuthSession({
    required this.token,
    required this.userId,
    required this.username,
  });

  /// Token JWT para el header `Authorization: Bearer`.
  final String token;

  /// Identificador único del usuario en el backend.
  final String userId;

  /// Nombre visible del jugador.
  final String username;

  /// Identificador de dominio del jugador (equivale a [userId]).
  Identifier get playerId => Identifier(userId);

  /// Indica si la sesión tiene un token válido para llamadas protegidas.
  bool get isAuthenticated => token.isNotEmpty;

  /// Cabecera HTTP lista para inyectar en peticiones protegidas.
  Map<String, String> get authorizationHeader => {
        'Authorization': 'Bearer $token',
      };
}
