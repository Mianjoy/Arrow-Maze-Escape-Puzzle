import 'package:flutter/foundation.dart';

import '../../application/use_cases/fire_arrow_use_case.dart';
import '../../application/use_cases/start_game_use_case.dart';
import '../../domain/domain.dart';

/// Controlador (ChangeNotifier) de la pantalla de juego.
///
/// Orquesta [StartGameUseCase]/[FireArrowUseCase] y expone el [Game] actual
/// (y el último [MoveResult]) a la UI de forma observable.
class GameController extends ChangeNotifier {
  /// Crea el controlador con los casos de uso de inicio y disparo.
  GameController({
    required StartGameUseCase startGameUseCase,
    required FireArrowUseCase fireArrowUseCase,
  })  : _startGameUseCase = startGameUseCase,
        _fireArrowUseCase = fireArrowUseCase;

  final StartGameUseCase _startGameUseCase;
  final FireArrowUseCase _fireArrowUseCase;

  Game? _game;
  MoveResult? _lastMoveResult;
  bool _isLoading = false;

  /// Partida actual, o `null` mientras aún no inicia.
  Game? get game => _game;

  /// Resultado del último movimiento intentado, o `null` si no hubo ninguno.
  MoveResult? get lastMoveResult => _lastMoveResult;

  /// Indica si se está iniciando/reiniciando la partida.
  bool get isLoading => _isLoading;

  /// Inicia una nueva partida sobre [level].
  Future<void> startGame(Level level) async {
    _isLoading = true;
    notifyListeners();

    _game = await _startGameUseCase.execute(
      gameId: Identifier('game-${level.id.value}-${DateTime.now().millisecondsSinceEpoch}'),
      playerId: const Identifier('local-player'),
      level: level,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Procesa un toque del jugador sobre la celda en [position].
  Future<void> onCellTapped(Position position) async {
    final currentGame = _game;
    if (currentGame == null || !currentGame.isPlayable) return;

    final outcome = await _fireArrowUseCase.execute(game: currentGame, position: position);
    _game = outcome.game;
    _lastMoveResult = outcome.result;
    notifyListeners();
  }

  /// Reinicia la partida actual desde cero sobre el mismo nivel.
  Future<void> retry() async {
    final currentLevel = _game?.level;
    if (currentLevel == null) return;
    await startGame(currentLevel);
  }
}
