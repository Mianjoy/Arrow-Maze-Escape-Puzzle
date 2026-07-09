import 'package:flutter/foundation.dart';

import '../../application/use_cases/ensure_initial_progress_use_case.dart';
import '../../application/use_cases/get_player_progress_use_case.dart';
import '../../application/use_cases/load_levels_use_case.dart';
import '../../domain/domain.dart';

/// Controlador de selección de nivel con progreso local (bloqueos y estrellas).
class LevelSelectController extends ChangeNotifier {
  /// Crea el controlador con casos de uso y el [playerId] del jugador activo.
  LevelSelectController({
    required LoadLevelsUseCase loadLevelsUseCase,
    required EnsureInitialProgressUseCase ensureInitialProgressUseCase,
    required GetPlayerProgressUseCase getPlayerProgressUseCase,
    required Identifier playerId,
  })  : _loadLevelsUseCase = loadLevelsUseCase,
        _ensureInitialProgressUseCase = ensureInitialProgressUseCase,
        _getPlayerProgressUseCase = getPlayerProgressUseCase,
        _playerId = playerId;

  final LoadLevelsUseCase _loadLevelsUseCase;
  final EnsureInitialProgressUseCase _ensureInitialProgressUseCase;
  final GetPlayerProgressUseCase _getPlayerProgressUseCase;
  final Identifier _playerId;

  List<Level> _levels = const [];
  PlayerProgress? _progress;
  bool _isLoading = false;
  Object? _error;

  /// Niveles del catálogo ordenados por [Level.levelNumber].
  List<Level> get levels => _levels;

  /// Progreso local del jugador (desbloqueos y récords).
  PlayerProgress? get progress => _progress;

  /// Indica si la carga está en curso.
  bool get isLoading => _isLoading;

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
