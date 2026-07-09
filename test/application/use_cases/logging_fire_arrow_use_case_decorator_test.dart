import 'package:arrow_maze_escape_puzzle/application/ports/i_use_case_logger.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/fire_arrow_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/logging_fire_arrow_use_case_decorator.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

/// Logger falso que solo acumula los mensajes recibidos, para inspeccionar
/// en las aserciones sin depender de `dart:developer`.
class _FakeUseCaseLogger implements IUseCaseLogger {
  final List<String> messages = [];

  @override
  void log(String message) => messages.add(message);
}

/// [IFireArrowUseCase] falso que devuelve un resultado fijo o lanza, para
/// probar el decorador de forma aislada del caso de uso real.
class _StubFireArrowUseCase implements IFireArrowUseCase {
  _StubFireArrowUseCase({this.result, this.error});

  final ({Game game, MoveResult result})? result;
  final Object? error;

  @override
  Future<({Game game, MoveResult result})> execute({
    required Game game,
    required Position position,
  }) async {
    if (error != null) throw error!;
    return result!;
  }
}

Level _buildLevel() {
  return const Level(
    id: Identifier('level-aop-test'),
    difficulty: LevelDifficulty.easy,
    boardDefinition: LevelBoardDefinition(
      dimension: BoardDimension(rows: 1, columns: 2),
      cells: [
        LevelCellData(position: Position(row: 0, column: 0), direction: Direction(ArrowDirection.right)),
      ],
    ),
    playerStart: PlayerStart(position: Position(row: 0, column: 1)),
    parMoves: 3,
    optimalMoves: 1,
  );
}

Game _buildGame() {
  return Game.fromLevel(
    gameId: const Identifier('g1'),
    playerId: const Identifier('p1'),
    level: _buildLevel(),
  ).start();
}

void main() {
  group('LoggingFireArrowUseCaseDecorator', () {
    test(
        'should_return_the_inner_use_case_result_unchanged',
        () async {
      // Arrange
      final game = _buildGame();
      final expected = (game: game, result: MoveResult.noArrowAtCell());
      final logger = _FakeUseCaseLogger();
      final decorator = LoggingFireArrowUseCaseDecorator(
        inner: _StubFireArrowUseCase(result: expected),
        logger: logger,
      );

      // Act
      final outcome = await decorator.execute(game: game, position: const Position(row: 0, column: 0));

      // Assert: el decorador es transparente, no altera el resultado.
      expect(outcome.game, same(expected.game));
      expect(outcome.result, same(expected.result));
    });

    test(
        'should_log_board_state_before_and_after_execution',
        () async {
      // Arrange
      final game = _buildGame();
      final wonGame = game.performMove(
        arrowId: game.board.arrows.first.id,
        movementEngine: const ArrowMovementEngine(collisionValidator: CollisionValidator()),
      ).game;
      final logger = _FakeUseCaseLogger();
      final decorator = LoggingFireArrowUseCaseDecorator(
        inner: _StubFireArrowUseCase(
          result: (game: wonGame, result: MoveResult.extracted(arrowId: game.board.arrows.first.id)),
        ),
        logger: logger,
      );

      // Act
      await decorator.execute(game: game, position: const Position(row: 0, column: 0));

      // Assert: un mensaje de entrada y uno de salida, con estado del tablero.
      expect(logger.messages, hasLength(2));
      expect(logger.messages[0], contains('START'));
      expect(logger.messages[0], contains('arrowsRemaining'));
      expect(logger.messages[1], contains('END'));
      expect(logger.messages[1], contains('elapsedMs'));
    });

    test(
        'should_log_failure_and_rethrow_when_inner_use_case_throws',
        () async {
      // Arrange
      final game = _buildGame();
      final logger = _FakeUseCaseLogger();
      final decorator = LoggingFireArrowUseCaseDecorator(
        inner: _StubFireArrowUseCase(error: StateError('boom')),
        logger: logger,
      );

      // Act & Assert
      await expectLater(
        () => decorator.execute(game: game, position: const Position(row: 0, column: 0)),
        throwsA(isA<StateError>()),
      );
      expect(logger.messages, hasLength(2));
      expect(logger.messages.last, contains('FAILED'));
    });
  });
}
