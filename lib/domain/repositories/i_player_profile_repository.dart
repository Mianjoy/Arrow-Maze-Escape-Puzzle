import '../player/aggregates/player_profile.dart';
import '../shared/value_objects/identifier.dart';

/// Contrato de persistencia para perfiles de jugador ([PlayerProfile]).
abstract interface class IPlayerProfileRepository {
  /// Guarda o actualiza un perfil.
  Future<void> save(PlayerProfile profile);

  /// Busca un perfil por [playerId].
  Future<PlayerProfile?> findById(Identifier playerId);
}
