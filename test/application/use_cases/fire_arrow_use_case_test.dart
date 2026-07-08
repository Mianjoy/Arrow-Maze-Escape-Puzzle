import 'package:arrow_maze_escape_puzzle/application/use_cases/fire_arrow_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

import '../support/fake_repositories.dart';

void main() {
  /// Tablero 2x2 con una única flecha en (0,1) apuntando a la derecha,
  /// sin obstáculos en su trayectoria (se extrae en un solo movimiento).
  Game buildStartedGameWithSingleArrow() {
    var board = const BoardFactory().createEmpty(
      id: const Identifier('board-test'),
      dimension: const BoardDimension(rows: 2, columns: 2),
    );
    board = board.placeArrow(
      const Arrow(
        id: Identifier('arrow-1'),
        position: Position(row: 0, column: 1),
        direction: Direction(ArrowDirection.right),
      ),
    );

    return Game(
      id: const Identifier('game-test'),
      playerId: const Identifier('player-test'),
      level: buildTestLevel(),
      board: board,
    ).start();
  }

  group('FireArrowUseCase', () {
    test('extrae la flecha y persiste la partida actualizada cuando la celda tiene una flecha con camino libre', () async {
      // Arrange
      final gameRepository = FakeGameRepository();
      final useCase = FireArrowUseCase(gameRepository: gameRepository);
      final game = buildStartedGameWithSingleArrow();

      // Act
      final outcome = await useCase.execute(
        game: game,
        position: const Position(row: 0, column: 1),
      );

      // Assert
      expect(outcome.result.isExtracted, isTrue);
      expect(outcome.game.isWon, isTrue);
      expect(gameRepository.savedGames, hasLength(1));
    });

    test('no muta el juego ni persiste nada cuando se toca una celda vacía', () async {
      // Arrange
      final gameRepository = FakeGameRepository();
      final useCase = FireArrowUseCase(gameRepository: gameRepository);
      final game = buildStartedGameWithSingleArrow();

      // Act
      final outcome = await useCase.execute(
        game: game,
        position: const Position(row: 1, column: 0),
      );

      // Assert
      expect(outcome.result.isNoArrowAtCell, isTrue);
      expect(outcome.game, same(game));
      expect(gameRepository.savedGames, isEmpty);
    });

    test('no muta el juego cuando se vuelve a tocar una flecha ya bloqueada', () async {
      // Arrange: dos flechas enfrentadas en fila 0 de un tablero 1x2 — la
      // primera en dispararse bloquea a la otra permanentemente.
      var board = const BoardFactory().createEmpty(
        id: const Identifier('board-blocked-test'),
        dimension: const BoardDimension(rows: 1, columns: 2),
      );
      board = board.placeArrow(
        const Arrow(
          id: Identifier('arrow-a'),
          position: Position(row: 0, column: 0),
          direction: Direction(ArrowDirection.right),
        ),
      );
      board = board.placeArrow(
        const Arrow(
          id: Identifier('arrow-b'),
          position: Position(row: 0, column: 1),
          direction: Direction(ArrowDirection.left),
        ),
      );
      final game = Game(
        id: const Identifier('game-blocked-test'),
        playerId: const Identifier('player-test'),
        level: buildTestLevel(),
        board: board,
      ).start();

      final gameRepository = FakeGameRepository();
      final useCase = FireArrowUseCase(gameRepository: gameRepository);

      // Act: dispara arrow-a primero (queda bloqueada por arrow-b), luego
      // toca la misma celda de nuevo.
      final firstAttempt = await useCase.execute(game: game, position: const Position(row: 0, column: 0));
      final secondAttempt = await useCase.execute(game: firstAttempt.game, position: const Position(row: 0, column: 0));

      // Assert
      expect(firstAttempt.result.isBlocked, isTrue);
      expect(secondAttempt.result.isNoArrowAtCell, isTrue);
      expect(secondAttempt.game, same(firstAttempt.game));
    });
  });
}
