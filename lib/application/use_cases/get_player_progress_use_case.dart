import '../../domain/domain.dart';

/// Caso de uso: obtener el progreso local persistido de un jugador.
class GetPlayerProgressUseCase {
  /// Crea el caso de uso con el [progressRepository] configurado.
  const GetPlayerProgressUseCase({required IPlayerProgressRepository progressRepository})
      : _progressRepository = progressRepository;

  final IPlayerProgressRepository _progressRepository;

  /// Devuelve el progreso de [playerId] o `null` si aún no hay registro.
  Future<PlayerProgress?> execute(Identifier playerId) {
    return _progressRepository.findByPlayerId(playerId);
  }
}
