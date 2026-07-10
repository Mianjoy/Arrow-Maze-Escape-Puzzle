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
    test('should_extract_arrow_and_persist_game_when_cell_has_clear_path', () async {
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

    test('should_not_mutate_or_persist_game_when_empty_cell_is_tapped', () async {
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

    test('should_allow_retry_on_blocked_arrow_and_count_each_attempt_as_move', () async {
      // Arrange: dos flechas enfrentadas en fila 0 de un tablero 1x2 — se
      // bloquean mutuamente (ninguna puede salir jamás).
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

      // Act: dispara arrow-a (queda bloqueada), luego toca la misma celda otra vez.
      final firstAttempt = await useCase.execute(game: game, position: const Position(row: 0, column: 0));
      final secondAttempt = await useCase.execute(game: firstAttempt.game, position: const Position(row: 0, column: 0));

      // Assert: el segundo toque NO es un no-op — vuelve a evaluar la colisión
      // (sigue bloqueada) y cuenta como otro movimiento (no se congela).
      expect(firstAttempt.result.isBlocked, isTrue);
      expect(secondAttempt.result.isBlocked, isTrue);
      expect(secondAttempt.game.moveCount, firstAttempt.game.moveCount + 1);
    });

    test('should_extract_blocked_arrow_after_blocking_arrow_is_cleared', () async {
      // Arrange: tablero 1x3. arrow-b en (0,1) apunta a la derecha (sale
      // limpio); arrow-a en (0,0) apunta a la derecha pero la bloquea arrow-b.
      var board = const BoardFactory().createEmpty(
        id: const Identifier('board-unblock-test'),
        dimension: const BoardDimension(rows: 1, columns: 3),
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
          direction: Direction(ArrowDirection.right),
        ),
      );
      final game = Game(
        id: const Identifier('game-unblock-test'),
        playerId: const Identifier('player-test'),
        level: buildTestLevel(),
        board: board,
      ).start();

      final useCase = FireArrowUseCase(gameRepository: FakeGameRepository());

      // Act: (1) tocar arrow-a bloqueada, (2) extraer arrow-b, (3) tocar
      // arrow-a de nuevo — ahora con la trayectoria libre.
      final blocked = await useCase.execute(game: game, position: const Position(row: 0, column: 0));
      final clearedBlocker = await useCase.execute(game: blocked.game, position: const Position(row: 0, column: 1));
      final retried = await useCase.execute(game: clearedBlocker.game, position: const Position(row: 0, column: 0));

      // Assert: el primer intento se bloqueó, pero tras despejar el camino la
      // flecha antes bloqueada se extrae y el nivel queda resuelto (ganado).
      expect(blocked.result.isBlocked, isTrue);
      expect(clearedBlocker.result.isExtracted, isTrue);
      expect(retried.result.isExtracted, isTrue);
      expect(retried.game.isWon, isTrue);
    });
  });
}
