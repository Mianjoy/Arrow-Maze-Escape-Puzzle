import '../models/leaderboard_entry.dart';

/// Puerto de consulta remota del ranking (capa de aplicación).
///
/// `GetLeaderboardUseCase` depende de esta interfaz, no de la
/// implementación HTTP concreta (`LeaderboardApiClient`), para respetar DIP.
abstract interface class ILeaderboardApiClient {
  /// Obtiene el top de jugadores para [levelId].
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required String levelId,
    int? limit,
  });
}
