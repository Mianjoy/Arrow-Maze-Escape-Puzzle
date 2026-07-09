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
    test('pause() transiciona de inProgress a paused', () {
      // Arrange
      final game = buildStartedGame();

      // Act
      final paused = game.pause();

      // Assert
      expect(paused.status, GameStatus.paused);
      expect(paused.isPlayable, isFalse);
    });

    test('resume() vuelve de paused a inProgress', () {
      // Arrange
      final paused = buildStartedGame().pause();

      // Act
      final resumed = paused.resume();

      // Assert
      expect(resumed.status, GameStatus.inProgress);
      expect(resumed.isPlayable, isTrue);
    });

    test('pause() lanza InvalidMoveException si la partida no está en progreso', () {
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

    test('resume() lanza InvalidMoveException si la partida no está pausada', () {
      // Arrange
      final game = buildStartedGame();

      // Act & Assert
      expect(() => game.resume(), throwsA(isA<InvalidMoveException>()));
    });
  });

  group('Game.performMove — puntaje y porcentaje de progreso', () {
    const engine = ArrowMovementEngine(collisionValidator: CollisionValidator());

    test('suma puntos al extraer una flecha y refleja el 100% de avance', () {
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
