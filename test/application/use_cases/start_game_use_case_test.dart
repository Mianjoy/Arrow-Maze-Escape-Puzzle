import 'package:arrow_maze_escape_puzzle/application/use_cases/start_game_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

import '../support/fake_repositories.dart';

void main() {
  group('StartGameUseCase', () {
    test('crea la partida en estado inProgress y la persiste', () async {
      // Arrange
      final level = buildTestLevel();
      final gameRepository = FakeGameRepository();
      final useCase = StartGameUseCase(gameRepository: gameRepository);

      // Act
      final game = await useCase.execute(
        gameId: const Identifier('game-1'),
        playerId: const Identifier('player-1'),
        level: level,
      );

      // Assert
      expect(game.status, GameStatus.inProgress);
      expect(game.isPlayable, isTrue);
      expect(gameRepository.savedGames, hasLength(1));
      expect(gameRepository.savedGames.first.id, const Identifier('game-1'));
    });
  });
}
