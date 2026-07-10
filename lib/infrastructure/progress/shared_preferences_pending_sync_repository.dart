import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../application/models/pending_sync_entry.dart';
import '../../application/ports/i_pending_sync_repository.dart';

/// Persiste la cola de sincronizaciones pendientes en [SharedPreferences],
/// como una única lista JSON compartida entre jugadores del dispositivo
/// (cada entrada ya lleva su propio `playerId`).
class SharedPreferencesPendingSyncRepository implements IPendingSyncRepository {
  /// Crea el repositorio con las [prefs] ya resueltas.
  SharedPreferencesPendingSyncRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _key = 'pending_sync_queue';

  @override
  Future<void> add(PendingSyncEntry entry) async {
    final current = await loadAll();
    await saveAll([...current, entry]);
  }

  @override
  Future<List<PendingSyncEntry>> loadAll() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(PendingSyncEntry.fromJson)
        .toList();
  }

  @override
  Future<void> saveAll(List<PendingSyncEntry> entries) async {
    if (entries.isEmpty) {
      await _prefs.remove(_key);
      return;
    }
    await _prefs.setString(_key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}
