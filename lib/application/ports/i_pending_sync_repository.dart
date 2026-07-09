import '../models/pending_sync_entry.dart';

/// Puerto de persistencia para sincronizaciones de progreso pendientes de
/// reenviar al backend (encoladas cuando `POST /progress/sync` falla).
abstract interface class IPendingSyncRepository {
  /// Agrega [entry] a la cola de pendientes.
  Future<void> add(PendingSyncEntry entry);

  /// Devuelve todas las entradas pendientes actuales.
  Future<List<PendingSyncEntry>> loadAll();

  /// Reemplaza la cola completa por [entries] (usado tras drenarla).
  Future<void> saveAll(List<PendingSyncEntry> entries);
}
