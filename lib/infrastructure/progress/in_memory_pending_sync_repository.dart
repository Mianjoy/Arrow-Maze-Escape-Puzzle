import '../../application/models/pending_sync_entry.dart';
import '../../application/ports/i_pending_sync_repository.dart';

/// Implementación en memoria de [IPendingSyncRepository] (tests y valor por
/// defecto cuando no se dispone de `SharedPreferences`).
class InMemoryPendingSyncRepository implements IPendingSyncRepository {
  final List<PendingSyncEntry> _entries = [];

  @override
  Future<void> add(PendingSyncEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<PendingSyncEntry>> loadAll() async => List.unmodifiable(_entries);

  @override
  Future<void> saveAll(List<PendingSyncEntry> entries) async {
    _entries
      ..clear()
      ..addAll(entries);
  }
}
