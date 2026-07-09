import '../../infrastructure/http/leaderboard_api_client.dart';
import '../models/leaderboard_entry.dart';

/// Caso de uso: obtener el ranking de un nivel desde el backend.
class GetLeaderboardUseCase {
  /// Crea el caso de uso con [leaderboardApiClient].
  const GetLeaderboardUseCase({required LeaderboardApiClient leaderboardApiClient})
      : _leaderboardApiClient = leaderboardApiClient;

  final LeaderboardApiClient _leaderboardApiClient;

  /// Consulta `GET /leaderboard/:levelId` y devuelve las entradas ordenadas.
  Future<List<LeaderboardEntry>> execute({
    required String levelId,
    int? limit,
  }) {
    return _leaderboardApiClient.fetchLeaderboard(levelId: levelId, limit: limit);
  }
}
