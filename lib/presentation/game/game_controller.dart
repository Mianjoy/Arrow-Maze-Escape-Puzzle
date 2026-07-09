import 'package:flutter/foundation.dart';

import '../../application/models/record_victory_result.dart';
import '../../application/ports/i_audio_service.dart';
import '../../application/use_cases/fire_arrow_use_case.dart';
import '../../application/use_cases/record_victory_use_case.dart';
import '../../application/use_cases/start_game_use_case.dart';
import '../../domain/domain.dart';
import '../auth/auth_session_controller.dart';

/// Controlador de la pantalla de juego con audio y sincronización de victoria.
class GameController extends ChangeNotifier {
  /// Crea el controlador con casos de uso, sesión, audio y sync de victoria.
  GameController({
    required StartGameUseCase startGameUseCase,
    required FireArrowUseCase fireArrowUseCase,
    required AuthSessionController authSessionController,
    required IAudioService audioService,
    RecordVictoryUseCase? recordVictoryUseCase,
  })  : _startGameUseCase = startGameUseCase,
        _fireArrowUseCase = fireArrowUseCase,
        _authSessionController = authSessionController,
        _audioService = audioService,
        _recordVictoryUseCase = recordVictoryUseCase;

  final StartGameUseCase _startGameUseCase;
  final FireArrowUseCase _fireArrowUseCase;
  final AuthSessionController _authSessionController;
  final IAudioService _audioService;
  final RecordVictoryUseCase? _recordVictoryUseCase;

  Game? _game;
  MoveResult? _lastMoveResult;
  bool _isLoading = false;
  bool _isSyncingProgress = false;
  Object? _syncError;
  RecordVictoryResult? _lastVictoryResult;

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

  /// Inicia una nueva partida sobre [level] con el jugador autenticado.
  Future<void> startGame(Level level) async {
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
    notifyListeners();
  }

  /// Procesa un toque; reproduce audio y sincroniza progreso si gana.
  Future<void> onCellTapped(Position position) async {
    final currentGame = _game;
    if (currentGame == null || !currentGame.isPlayable) return;

    await _audioService.playTap();

    final outcome = await _fireArrowUseCase.execute(game: currentGame, position: position);
    _game = outcome.game;
    _lastMoveResult = outcome.result;

    if (outcome.game.isWon) {
      await _audioService.playVictory();
      await _syncVictoryIfPossible(outcome.game);
    } else if (outcome.game.isLost) {
      await _audioService.playDefeat();
    }

    notifyListeners();
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
      // Solo alcanza este catch si falló algo local (repositorio de progreso,
      // cálculo del siguiente nivel) — la sincronización remota ya se maneja
      // dentro de `execute` y nunca llega a lanzar por sí sola.
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
}
