import '../progress/aggregates/player_progress.dart';
import '../shared/value_objects/identifier.dart';

/// Contrato de persistencia para el progreso del jugador ([PlayerProgress]).
abstract interface class IPlayerProgressRepository {
  /// Guarda o actualiza el progreso.
  Future<void> save(PlayerProgress progress);

  /// Obtiene el progreso de un jugador por [playerId].
  Future<PlayerProgress?> findByPlayerId(Identifier playerId);
}
