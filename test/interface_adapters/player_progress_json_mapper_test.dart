import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/interface_adapters/player_progress_json_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlayerProgressJsonMapper round-trip conserva desbloqueos y estrellas', () {
    const mapper = PlayerProgressJsonMapper();
    const playerId = Identifier('player-1');
    const levelId = Identifier('level-01');

    final original = PlayerProgress(
      playerId: playerId,
      levels: {
        levelId: LevelProgress(
          levelId: levelId,
          status: LevelProgressStatus.completed,
          bestMoveCount: 2,
          bestTimeSeconds: 10,
          bestStars: StarRating.three,
          completionCount: 1,
        ),
      },
    );

    final decoded = mapper.decode(mapper.encode(original));

    expect(decoded.playerId, playerId);
    expect(decoded.progressFor(levelId)?.status, LevelProgressStatus.completed);
    expect(decoded.progressFor(levelId)?.bestStars?.value, 3);
  });
}
