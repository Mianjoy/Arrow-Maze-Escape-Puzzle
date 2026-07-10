import '../../domain/domain.dart';

/// Implementación en memoria de [IPlayerProgressRepository].
///
/// Mismo motivo que [InMemoryGameRepository]: desbloquea la capa de
/// aplicación/presentación sin comprometerse aún a una base de datos local.
class InMemoryPlayerProgressRepository implements IPlayerProgressRepository {
  final Map<String, PlayerProgress> _progressByPlayerId = {};

  /// Guarda o actualiza el progreso en el mapa interno.
  @override
  Future<void> save(PlayerProgress progress) async {
    _progressByPlayerId[progress.playerId.value] = progress;
  }

  /// Recupera el progreso de [playerId] o `null` si no existe.
  @override
  Future<PlayerProgress?> findByPlayerId(Identifier playerId) async {
    return _progressByPlayerId[playerId.value];
  }
}
