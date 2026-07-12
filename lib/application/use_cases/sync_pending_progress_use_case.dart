import '../models/auth_session.dart';
import '../models/pending_sync_entry.dart';
import '../ports/i_pending_sync_repository.dart';
import '../ports/i_progress_api_client.dart';

/// Caso de uso: reintenta las sincronizaciones de progreso que quedaron
/// pendientes de una sesión anterior sin red.
///
/// Se ejecuta como best-effort cada vez que se confirma que hay conexión
/// (p. ej. al cargar la lista de niveles); las entradas de otros jugadores
/// en el mismo dispositivo se dejan intactas.
class SyncPendingProgressUseCase {
  /// Crea el caso de uso con el repositorio de pendientes y el cliente HTTP.
  const SyncPendingProgressUseCase({
    required IPendingSyncRepository pendingSyncRepository,
    required IProgressApiClient progressApiClient,
  })  : _pendingSyncRepository = pendingSyncRepository,
        _progressApiClient = progressApiClient;

  final IPendingSyncRepository _pendingSyncRepository;
  final IProgressApiClient _progressApiClient;

  /// Reenvía las entradas pendientes de [session.playerId]; deja el resto de
  /// jugadores y las que sigan fallando en la cola para el próximo intento.
  Future<void> execute(AuthSession session) async {
    final all = await _pendingSyncRepository.loadAll();
    if (all.isEmpty) return;

    final playerId = session.playerId;
    final ownEntries = all.where((e) => e.playerId == playerId).toList();
    if (ownEntries.isEmpty) return;

    final stillFailing = <PendingSyncEntry>[];
    for (final entry in ownEntries) {
      try {
        await _progressApiClient.syncProgress(
          session: session,
          levelId: entry.levelId.value,
          score: entry.score,
          moves: entry.moves,
          timeInSeconds: entry.timeInSeconds,
          completed: true,
        );
      } catch (_) {
        stillFailing.add(entry);
      }
    }

    final untouched = all.where((e) => e.playerId != playerId);
    await _pendingSyncRepository.saveAll([...untouched, ...stillFailing]);
  }
}
