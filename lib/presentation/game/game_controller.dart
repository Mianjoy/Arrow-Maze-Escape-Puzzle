import '../../application/use_cases/fire_arrow_use_case.dart';
import '../../application/use_cases/record_victory_use_case.dart';
import '../../application/use_cases/start_game_use_case.dart';
import '../../domain/domain.dart';
import '../auth/auth_session_controller.dart';

/// Controlador (ChangeNotifier) de la pantalla de juego.
///
/// Orquesta [StartGameUseCase]/[FireArrowUseCase], sincroniza progreso al ganar
/// vía [RecordVictoryUseCase] y expone el [Game] actual a la UI.
class GameController extends ChangeNotifier {
  /// Crea el controlador con casos de uso, sesión y sync de victoria.
  GameController({
    required StartGameUseCase startGameUseCase,
    required FireArrowUseCase fireArrowUseCase,
    required AuthSessionController authSessionController,
    RecordVictoryUseCase? recordVictoryUseCase,
  })  : _startGameUseCase = startGameUseCase,
        _fireArrowUseCase = fireArrowUseCase,
        _authSessionController = authSessionController,
        _recordVictoryUseCase = recordVictoryUseCase;

  final StartGameUseCase _startGameUseCase;
  final FireArrowUseCase _fireArrowUseCase;
  final AuthSessionController _authSessionController;
  final RecordVictoryUseCase? _recordVictoryUseCase;

  Game? _game;
  MoveResult? _lastMoveResult;
  bool _isLoading = false;
  bool _isSyncingProgress = false;
  Object? _syncError;

  /// Partida actual, o `null` mientras aún no inicia.
  Game? get game => _game;

  /// Resultado del último movimiento intentado, o `null` si no hubo ninguno.
  MoveResult? get lastMoveResult => _lastMoveResult;

  /// Indica si se está iniciando/reiniciando la partida.
  bool get isLoading => _isLoading;

  /// Indica si se está enviando progreso al backend tras una victoria.
  bool get isSyncingProgress => _isSyncingProgress;

  /// Error de la última sincronización de progreso (si falló).
  Object? get syncError => _syncError;

  /// Inicia una nueva partida sobre [level] con el jugador autenticado.
  Future<void> startGame(Level level) async {
    _isLoading = true;
    _syncError = null;
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

  /// Procesa un toque del jugador; sincroniza progreso si la partida termina en victoria.
  Future<void> onCellTapped(Position position) async {
    final currentGame = _game;
    if (currentGame == null || !currentGame.isPlayable) return;

    final outcome = await _fireArrowUseCase.execute(game: currentGame, position: position);
    _game = outcome.game;
    _lastMoveResult = outcome.result;

    if (outcome.game.isWon) {
      await _syncVictoryIfPossible(outcome.game);
    }

    notifyListeners();
  }

  /// Envía el progreso al backend cuando hay sesión y caso de uso configurado.
  Future<void> _syncVictoryIfPossible(Game wonGame) async {
    final session = _authSessionController.session;
    final recordVictory = _recordVictoryUseCase;
    if (session == null || recordVictory == null) return;

    _isSyncingProgress = true;
    _syncError = null;
    notifyListeners();

    try {
      await recordVictory.execute(game: wonGame, session: session);
    } catch (error) {
      _syncError = error;
    } finally {
      _isSyncingProgress = false;
      notifyListeners();
    }
  }

  /// Reinicia la partida actual desde cero sobre el mismo nivel.
  Future<void> retry() async {
    final currentLevel = _game?.level;
    if (currentLevel == null) return;
    await startGame(currentLevel);
  }
}
