import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../application/models/record_victory_result.dart';
import '../../application/ports/i_audio_service.dart';
import '../../application/use_cases/fire_arrow_use_case.dart';
import '../../application/use_cases/record_victory_use_case.dart';
import '../../application/use_cases/start_game_use_case.dart';
import '../../domain/domain.dart';
import '../auth/auth_session_controller.dart';

/// Controlador de la pantalla de juego con audio, temporizador y sync de victoria.
class GameController extends ChangeNotifier {
  /// Crea el controlador con casos de uso, sesión, audio y sync de victoria.
  GameController({
    required StartGameUseCase startGameUseCase,
    required IFireArrowUseCase fireArrowUseCase,
    required AuthSessionController authSessionController,
    required IAudioService audioService,
    RecordVictoryUseCase? recordVictoryUseCase,
  })  : _startGameUseCase = startGameUseCase,
        _fireArrowUseCase = fireArrowUseCase,
        _authSessionController = authSessionController,
        _audioService = audioService,
        _recordVictoryUseCase = recordVictoryUseCase;

  final StartGameUseCase _startGameUseCase;
  final IFireArrowUseCase _fireArrowUseCase;
  final AuthSessionController _authSessionController;
  final IAudioService _audioService;
  final RecordVictoryUseCase? _recordVictoryUseCase;

  Game? _game;
  MoveResult? _lastMoveResult;
  bool _isLoading = false;
  bool _isSyncingProgress = false;
  Object? _syncError;
  RecordVictoryResult? _lastVictoryResult;
  Timer? _gameTimer;

  /// Partida actual, o `null` mientras aún no inicia.
  Game? get game => _game;

  /// Resultado del último movimiento intentado.
  MoveResult? get lastMoveResult => _lastMoveResult;

  /// Indica si se está iniciando o reiniciando la partida.
  bool get isLoading => _isLoading;

  /// Indica si se envía progreso al backend tras una victoria.
  bool get isSyncingProgress => _isSyncingProgress;

  /// Error de la última sincronización remota.
  Object? get syncError => _syncError;

  /// Resultado de la última victoria (progreso y siguiente nivel).
  RecordVictoryResult? get lastVictoryResult => _lastVictoryResult;

  /// Libera el temporizador de partida (llamar desde [GameScreen.dispose]).
  void disposeController() {
    _stopGameTimer();
  }

  /// Inicia una nueva partida sobre [level] con el jugador autenticado.
  Future<void> startGame(Level level) async {
    _stopGameTimer();
    _isLoading = true;
    _syncError = null;
    _lastVictoryResult = null;
    notifyListeners();

    final playerId = _authSessionController.session?.playerId ?? const Identifier('local-player');

    _game = await _startGameUseCase.execute(
      gameId: Identifier('game-${level.id.value}-${DateTime.now().millisecondsSinceEpoch}'),
      playerId: playerId,
      level: level,
    );

    _isLoading = false;
    _startGameTimer();
    notifyListeners();
  }

  /// Procesa un toque; reproduce audio según el resultado y sincroniza progreso si gana.
  Future<void> onCellTapped(Position position) async {
    final currentGame = _game;
    if (currentGame == null || !currentGame.isPlayable) return;

    final outcome = await _fireArrowUseCase.execute(game: currentGame, position: position);
    _game = outcome.game;
    _lastMoveResult = outcome.result;

    if (outcome.game.isWon) {
      _stopGameTimer();
      await _audioService.playLevelCleared();
      await _syncVictoryIfPossible(outcome.game);
    } else if (outcome.game.isLost) {
      _stopGameTimer();
      await _playLossAudio(outcome.game);
    } else if (outcome.result.isExtracted) {
      await _audioService.playArrowExtracted();
    } else if (_isBlockedByAnotherArrow(outcome.game, outcome.result)) {
      await _audioService.playMovementNotAllowed();
    }

    notifyListeners();
  }

  /// Indica si el bloqueo fue por colisión con otra flecha (no muro ni celda vacía).
  bool _isBlockedByAnotherArrow(Game game, MoveResult result) {
    if (!result.isBlocked) return false;

    final blockingPosition = result.blockingPosition;
    final blockedArrowId = result.arrowId;
    if (blockingPosition == null || blockedArrowId == null) return false;

    if (game.board.cellAt(blockingPosition).isWall) return false;

    return game.board.activeArrows.any(
      (other) => other.id != blockedArrowId && other.occupies(blockingPosition),
    );
  }

  /// Reproduce el sonido de derrota según la causa (tiempo o movimientos).
  Future<void> _playLossAudio(Game game) async {
    if (game.lossMessage == GameLossMessage.timeExceeded) {
      await _audioService.playTimeUp();
    } else {
      await _audioService.playDefeat();
    }
  }

  /// Registra victoria local/remota cuando hay sesión y caso de uso configurado.
  Future<void> _syncVictoryIfPossible(Game wonGame) async {
    final session = _authSessionController.session;
    final recordVictory = _recordVictoryUseCase;
    if (session == null || recordVictory == null) return;

    _isSyncingProgress = true;
    _syncError = null;
    notifyListeners();

    try {
      _lastVictoryResult = await recordVictory.execute(game: wonGame, session: session);
      _syncError = _lastVictoryResult?.syncError;
    } catch (error) {
      _syncError = error;
    } finally {
      _isSyncingProgress = false;
      notifyListeners();
    }
  }

  /// Reinicia la partida actual sobre el mismo nivel.
  Future<void> retry() async {
    final currentLevel = _game?.level;
    if (currentLevel == null) return;
    await startGame(currentLevel);
  }

  void _startGameTimer() {
    _stopGameTimer();
    final game = _game;
    if (game == null || !game.isPlayable) return;

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onGameTimerTick());
  }

  void _stopGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void _onGameTimerTick() {
    final game = _game;
    if (game == null || !game.isPlayable) {
      _stopGameTimer();
      return;
    }

    if (game.elapsedSeconds >= game.level.playableTimeLimitSeconds) {
      _stopGameTimer();
      _game = game.copyWith(
        status: GameStatus.lost,
        lossMessage: GameLossMessage.timeExceeded,
        finishedAt: DateTime.now().toUtc(),
      );
      unawaited(_playLossAudio(_game!));
      notifyListeners();
      return;
    }

    notifyListeners();
  }
}
