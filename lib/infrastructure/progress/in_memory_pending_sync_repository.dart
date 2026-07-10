import '../../application/models/pending_sync_entry.dart';
import '../../application/ports/i_pending_sync_repository.dart';

/// Implementación en memoria de [IPendingSyncRepository] (tests y valor por
/// defecto cuando no se dispone de `SharedPreferences`).
class InMemoryPendingSyncRepository implements IPendingSyncRepository {
  final List<PendingSyncEntry> _entries = [];

  /// Encola una sincronización pendiente en memoria.
  @override
  Future<void> add(PendingSyncEntry entry) async {
    _entries.add(entry);
  }

  /// Devuelve todas las entradas pendientes almacenadas.
  @override
  Future<List<PendingSyncEntry>> loadAll() async => List.unmodifiable(_entries);

  /// Reemplaza la cola completa con [entries].
  @override
  Future<void> saveAll(List<PendingSyncEntry> entries) async {
    _entries
      ..clear()
      ..addAll(entries);
  }
}
