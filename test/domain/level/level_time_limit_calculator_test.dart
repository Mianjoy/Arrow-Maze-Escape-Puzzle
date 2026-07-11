import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const calculator = LevelTimeLimitCalculator();

  final baseLevel = Level(
    id: const Identifier('level-time-test'),
    difficulty: LevelDifficulty.medium,
    boardDefinition: const LevelBoardDefinition(
      dimension: BoardDimension(rows: 3, columns: 3),
    ),
    playerStart: const PlayerStart(position: Position(row: 0, column: 0)),
    parMoves: 10,
    optimalMoves: 5,
  );

  test('resolve uses configured timeLimit when present', () {
    final level = Level(
      id: const Identifier('wired'),
      difficulty: LevelDifficulty.easy,
      boardDefinition: baseLevel.boardDefinition,
      playerStart: baseLevel.playerStart,
      parMoves: 10,
      optimalMoves: 5,
      timeLimit: 90,
    );

    expect(calculator.resolve(level), 90);
    expect(level.playableTimeLimitSeconds, 90);
  });

  test('resolve calculates from optimalMoves when timeLimit is absent', () {
    expect(calculator.resolve(baseLevel), 55);
    expect(baseLevel.playableTimeLimitSeconds, 55);
  });
}
