import 'package:flutter/foundation.dart';

import '../../application/models/auth_session.dart';
import '../../application/use_cases/ensure_initial_progress_use_case.dart';
import '../../application/use_cases/get_player_progress_use_case.dart';
import '../../application/use_cases/load_levels_use_case.dart';
import '../../application/use_cases/pull_remote_progress_use_case.dart';
import '../../application/use_cases/sync_pending_progress_use_case.dart';
import '../../domain/domain.dart';

/// Controlador de selección de nivel con progreso local (bloqueos y estrellas).
class LevelSelectController extends ChangeNotifier {
  /// Crea el controlador con casos de uso y el [playerId] del jugador activo.
  LevelSelectController({
    required LoadLevelsUseCase loadLevelsUseCase,
    required EnsureInitialProgressUseCase ensureInitialProgressUseCase,
    required GetPlayerProgressUseCase getPlayerProgressUseCase,
    required Identifier playerId,
    SyncPendingProgressUseCase? syncPendingProgressUseCase,
    PullRemoteProgressUseCase? pullRemoteProgressUseCase,
    AuthSession? session,
  })  : _loadLevelsUseCase = loadLevelsUseCase,
        _ensureInitialProgressUseCase = ensureInitialProgressUseCase,
        _getPlayerProgressUseCase = getPlayerProgressUseCase,
        _playerId = playerId,
        _syncPendingProgressUseCase = syncPendingProgressUseCase,
        _pullRemoteProgressUseCase = pullRemoteProgressUseCase,
        _session = session;

  final LoadLevelsUseCase _loadLevelsUseCase;
  final EnsureInitialProgressUseCase _ensureInitialProgressUseCase;
  final GetPlayerProgressUseCase _getPlayerProgressUseCase;
  final Identifier _playerId;
  final SyncPendingProgressUseCase? _syncPendingProgressUseCase;
  final PullRemoteProgressUseCase? _pullRemoteProgressUseCase;
  final AuthSession? _session;

  List<Level> _levels = const [];
  PlayerProgress? _progress;
  bool _isLoading = false;
  bool _isOffline = false;
  Object? _error;

  /// Niveles del catálogo ordenados por [Level.levelNumber].
  List<Level> get levels => _levels;

  /// Progreso local del jugador (desbloqueos y récords).
  PlayerProgress? get progress => _progress;

  /// Indica si la carga está en curso.
  bool get isLoading => _isLoading;

  /// Indica si la última carga no pudo contactar al servidor (modo offline).
  ///
  /// El juego sigue siendo jugable con el progreso local; el progreso se
  /// sincronizará cuando vuelva la conexión.
  bool get isOffline => _isOffline;

  /// Error de la última carga, o `null` si fue exitosa.
  Object? get error => _error;

  /// Carga catálogo, asegura progreso inicial y notifica a la UI.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _levels = await _loadLevelsUseCase.execute();
      _levels = List<Level>.from(_levels)
        ..sort((a, b) {
          final an = a.levelNumber ?? 0;
          final bn = b.levelNumber ?? 0;
          if (an != bn) return an.compareTo(bn);
          return a.id.value.compareTo(b.id.value);
        });
      _progress = await _ensureInitialProgressUseCase.execute(_playerId);
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    await _syncWithServer();
  }

  /// Sincroniza con el servidor de forma best-effort: descarga y fusiona el
  /// progreso remoto, y reenvía las victorias pendientes.
  ///
  /// Si alguna llamada falla por falta de red, se marca [isOffline] pero el
  /// juego sigue siendo jugable con el progreso local ya cargado.
  Future<void> _syncWithServer() async {
    final session = _session;
    if (session == null) return;

    var offline = false;

    final pull = _pullRemoteProgressUseCase;
    if (pull != null) {
      try {
        _progress = await pull.execute(session);
        notifyListeners();
      } catch (_) {
        offline = true;
      }
    }

    final sync = _syncPendingProgressUseCase;
    if (sync != null) {
      try {
        // El progreso local ya refleja las victorias (se guardaron en
        // `RecordVictoryUseCase` sin depender de la red); este intento solo
        // reenvía al backend lo que quedó pendiente.
        await sync.execute(session);
      } catch (_) {
        offline = true;
      }
    }

    if (offline != _isOffline) {
      _isOffline = offline;
      notifyListeners();
    }
  }

  /// Recarga solo el progreso (p. ej. al volver de una partida ganada).
  Future<void> refreshProgress() async {
    _progress = await _getPlayerProgressUseCase.execute(_playerId);
    notifyListeners();
  }

  /// Indica si [level] está desbloqueado para jugar.
  bool isLevelUnlocked(Level level) {
    final lp = _progress?.progressFor(level.id);
    if (lp == null) return false;
    return lp.status != LevelProgressStatus.locked;
  }

  /// Indica si [level] fue completado al menos una vez.
  bool isLevelCompleted(Level level) {
    return _progress?.progressFor(level.id)?.status == LevelProgressStatus.completed;
  }

  /// Mejor calificación en estrellas para [level], o `null` si no completó.
  int? starsFor(Level level) {
    return _progress?.progressFor(level.id)?.bestStars?.value;
  }
}
