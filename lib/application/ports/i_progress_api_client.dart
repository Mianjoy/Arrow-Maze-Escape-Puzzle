import '../models/auth_session.dart';
import '../models/remote_player_progress.dart';

/// Puerto de sincronización remota de progreso (capa de aplicación).
///
/// Los casos de uso de progreso dependen de esta interfaz, no de la
/// implementación HTTP concreta (`ProgressApiClient`), para respetar DIP.
abstract interface class IProgressApiClient {
  /// Envía el progreso de un nivel completado al backend.
  Future<void> syncProgress({
    required AuthSession session,
    required String levelId,
    required int score,
    required int moves,
    required int timeInSeconds,
    required bool completed,
  });

  /// Sincroniza los coleccionables desbloqueados del jugador.
  Future<void> syncCollectibles({
    required AuthSession session,
    required List<String> collectibleIds,
  });

  /// Descarga el progreso completo del jugador desde el servidor.
  Future<RemotePlayerProgress> fetchProgress(AuthSession session);
}
