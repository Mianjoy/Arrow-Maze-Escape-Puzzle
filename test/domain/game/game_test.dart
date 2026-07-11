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

    test('should_freeze_elapsedSeconds_while_paused', () {
      final started = buildStartedGame();
      final paused = started.pause();

      expect(paused.elapsedSeconds, started.elapsedSeconds);
    });

    test('should_clear_pausedAt_after_resume', () {
      // Arrange
      final paused = buildStartedGame().pause();

      // Act
      final resumed = paused.resume();

      // Assert: `copyWith` resuelve parámetros nulos con `?? this.campo`, así
      // que `resume()` debe usar `clearPausedAt: true` (no `pausedAt: null`)
      // para que de verdad se limpie; si no, `elapsedSeconds` queda congelado
      // para siempre tras la primera pausa/reanudación (p. ej. al visitar
      // Ajustes o Leaderboard durante una partida).
      expect(resumed.pausedAt, isNull);
    });

    test('should_not_double_subtract_pause_duration_after_resume', () async {
      // Arrange: una partida que empezó hace 10s, se pausó por 3s y ya reanudó.
      final now = DateTime.now().toUtc();
      final game = Game(
        id: const Identifier('game-test'),
        playerId: const Identifier('player-test'),
        level: buildLevel(),
        board: buildSingleArrowBoard(),
        status: GameStatus.paused,
        startedAt: now.subtract(const Duration(seconds: 10)),
        pausedAt: now.subtract(const Duration(seconds: 3)),
      );

      // Act
      final resumed = game.resume();
      final elapsedRightAfterResume = resumed.elapsedSeconds;
      await Future<void>.delayed(const Duration(seconds: 2));
      final elapsedLater = resumed.elapsedSeconds;

      // Assert: sin el bug (`pausedAt` colgado del pause anterior), el tiempo
      // transcurrido debe seguir avanzando con el reloj real tras reanudar —
      // con el bug quedaba congelado (la resta de `now - pausedAt` crecía al
      // mismo ritmo que `now - startedAt`, cancelándose exactamente).
      expect(elapsedLater, greaterThanOrEqualTo(elapsedRightAfterResume + 2));
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
