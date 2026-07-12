import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

Level _buildLevel({required int levelNumber, int arrowCount = 1}) {
  return Level(
    id: Identifier('level-$levelNumber'),
    levelNumber: levelNumber,
    difficulty: LevelDifficulty.easy,
    boardDefinition: LevelBoardDefinition(
      dimension: BoardDimension(rows: 1, columns: arrowCount),
      cells: List.generate(
        arrowCount,
        (index) => LevelCellData(
          position: Position(row: 0, column: index),
          direction: const Direction(ArrowDirection.right),
        ),
      ),
    ),
    playerStart: PlayerStart(position: Position(row: 0, column: arrowCount)),
    parMoves: 5,
    optimalMoves: arrowCount,
  );
}

void main() {
  group('MetaCollectibleUnlockPolicy', () {
    test('should_unlock_on_even_milestone_with_three_stars_and_full_score', () {
      final level = _buildLevel(levelNumber: 2, arrowCount: 2);

      expect(
        MetaCollectibleUnlockPolicy.shouldUnlock(
          levelNumber: 2,
          starsEarned: StarRating.three,
          score: 200,
          level: level,
        ),
        isTrue,
      );
    });

    test('should_not_unlock_on_odd_level_number', () {
      final level = _buildLevel(levelNumber: 1);

      expect(
        MetaCollectibleUnlockPolicy.shouldUnlock(
          levelNumber: 1,
          starsEarned: StarRating.three,
          score: 100,
          level: level,
        ),
        isFalse,
      );
    });

    test('should_not_unlock_without_three_stars', () {
      final level = _buildLevel(levelNumber: 2);

      expect(
        MetaCollectibleUnlockPolicy.shouldUnlock(
          levelNumber: 2,
          starsEarned: StarRating.two,
          score: 100,
          level: level,
        ),
        isFalse,
      );
    });

    test('should_not_unlock_without_full_score', () {
      final level = _buildLevel(levelNumber: 2, arrowCount: 2);

      expect(
        MetaCollectibleUnlockPolicy.shouldUnlock(
          levelNumber: 2,
          starsEarned: StarRating.three,
          score: 100,
          level: level,
        ),
        isFalse,
      );
    });

    test('should_unlock_final_collectible_only_on_last_level', () {
      final level = _buildLevel(levelNumber: 22, arrowCount: 1);

      expect(
        MetaCollectibleUnlockPolicy.shouldUnlock(
          levelNumber: 22,
          starsEarned: StarRating.three,
          score: 100,
          level: level,
        ),
        isTrue,
      );

      expect(
        MetaCollectibleUnlockPolicy.collectibleForLevel(22)?.id,
        'collectible-final',
      );
    });

    test('should_not_unlock_collectible_on_odd_levels_except_final', () {
      final level = _buildLevel(levelNumber: 21);

      expect(
        MetaCollectibleUnlockPolicy.shouldUnlock(
          levelNumber: 21,
          starsEarned: StarRating.three,
          score: 100,
          level: level,
        ),
        isFalse,
      );
    });
  });
}
