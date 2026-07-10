import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

/// Pruebas de los comportamientos portados desde la rama `Integracion`:
/// pausa/reanudación (`Partida.pausar()/reanudar()`) y puntaje/porcentaje
/// de progreso (`EstadoPartida.puntuacion`/`porcentajeCompletado()`).
void main() {
  /// Construye un nivel mínimo de prueba (2x2, sin celdas predefinidas).
  Level buildLevel() {
    return const Level(
      id: Identifier('level-test'),
      difficulty: LevelDifficulty.easy,
      boardDefinition: LevelBoardDefinition(
        dimension: BoardDimension(rows: 2, columns: 2),
        cells: [],
      ),
      playerStart: PlayerStart(position: Position(row: 0, column: 0)),
      parMoves: 5,
      optimalMoves: 1,
    );
  }

  /// Construye un tablero 2x2 con una única flecha que puede extraerse
  /// en un solo movimiento (sin obstáculos en su trayectoria).
  Board buildSingleArrowBoard() {
    var board = const BoardFactory().createEmpty(
      id: const Identifier('board-test'),
      dimension: const BoardDimension(rows: 2, columns: 2),
    );
    const arrow = Arrow(
      id: Identifier('arrow-1'),
      position: Position(row: 0, column: 1),
      direction: Direction(ArrowDirection.right),
    );
    return board.placeArrow(arrow);
  }

  Game buildStartedGame() {
    return Game(
      id: const Identifier('game-test'),
      playerId: const Identifier('player-test'),
      level: buildLevel(),
      board: buildSingleArrowBoard(),
    ).start();
  }

  group('Game.pause / Game.resume', () {
    test('should_transition_pause_from_inProgress_to_paused', () {
      // Arrange
      final game = buildStartedGame();

      // Act
      final paused = game.pause();

      // Assert
      expect(paused.status, GameStatus.paused);
      expect(paused.isPlayable, isFalse);
    });

    test('should_transition_resume_from_paused_to_inProgress', () {
      // Arrange
      final paused = buildStartedGame().pause();

      // Act
      final resumed = paused.resume();

      // Assert
      expect(resumed.status, GameStatus.inProgress);
      expect(resumed.isPlayable, isTrue);
    });

    test('should_throw_InvalidMoveException_when_pause_called_outside_inProgress', () {
      // Arrange: una partida recién creada, aún no iniciada (status ready).
      final game = Game(
        id: const Identifier('game-test'),
        playerId: const Identifier('player-test'),
        level: buildLevel(),
        board: buildSingleArrowBoard(),
      );

      // Act & Assert
      expect(() => game.pause(), throwsA(isA<InvalidMoveException>()));
    });

    test('should_throw_InvalidMoveException_when_resume_called_outside_paused', () {
      // Arrange
      final game = buildStartedGame();

      // Act & Assert
      expect(() => game.resume(), throwsA(isA<InvalidMoveException>()));
    });
  });

  group('Game.performMove — score and progress percentage', () {
    const engine = ArrowMovementEngine(collisionValidator: CollisionValidator());

    test('should_add_score_on_arrow_extract_and_reach_100_percent_progress', () {
      // Arrange
      final game = buildStartedGame();

      // Act
      final outcome = game.performMove(
        arrowId: const Identifier('arrow-1'),
        movementEngine: engine,
      );

      // Assert
      expect(outcome.result.isExtracted, isTrue);
      expect(outcome.game.score, 100);
      expect(outcome.game.completionPercentage(), 100.0);
      expect(outcome.game.status, GameStatus.won);
    });
  });
}
