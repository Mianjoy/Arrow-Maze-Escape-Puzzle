import '../game/aggregates/game.dart';
import '../shared/value_objects/identifier.dart';

/// Contrato de persistencia para partidas ([Game]).
///
/// La implementación concreta pertenece a la capa de infraestructura.
abstract interface class IGameRepository {
  /// Guarda o actualiza una partida.
  Future<void> save(Game game);

  /// Obtiene una partida por [id] o `null` si no existe.
  Future<Game?> findById(Identifier id);

  /// Lista las partidas activas de un jugador.
  Future<List<Game>> findActiveByPlayer(Identifier playerId);
}
