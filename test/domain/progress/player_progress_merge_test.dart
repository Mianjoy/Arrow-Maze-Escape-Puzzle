import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

/// Pruebas de `PlayerProgress.mergeRemoteLevel`: fusión best-of del progreso
/// remoto (servidor) con el local.
void main() {
  const levelId = Identifier('level-01');

  test(
      'should_mark_level_completed_when_remote_is_completed_and_local_is_not',
      () {
    // Arrange: local solo desbloqueado, sin completar.
    final local = PlayerProgress(
      playerId: const Identifier('u1'),
      levels: {
        levelId: const LevelProgress(levelId: levelId, status: LevelProgressStatus.unlocked),
      },
    );

    // Act
    final merged = local.mergeRemoteLevel(
      levelId: levelId,
      remoteBestMoveCount: 4,
      remoteBestTimeSeconds: 12,
      remoteCompleted: true,
    );

    // Assert
    final lp = merged.progressFor(levelId)!;
    expect(lp.status, LevelProgressStatus.completed);
    expect(lp.bestMoveCount, 4);
    expect(lp.bestTimeSeconds, 12);
    expect(lp.bestStars, isNotNull); // fallback StarRating.one
  });

  test(
      'should_keep_local_records_when_they_are_better_than_remote',
      () {
    // Arrange: local ya completado con mejores métricas que el remoto.
    final local = PlayerProgress(
      playerId: const Identifier('u1'),
      levels: {
        levelId: const LevelProgress(
          levelId: levelId,
          status: LevelProgressStatus.completed,
          bestMoveCount: 2,
          bestTimeSeconds: 5,
          bestStars: StarRating.three,
        ),
      },
    );

    // Act
    final merged = local.mergeRemoteLevel(
      levelId: levelId,
      remoteBestMoveCount: 9,
      remoteBestTimeSeconds: 30,
      remoteCompleted: true,
    );

    // Assert: conserva lo mejor local, no retrocede.
    final lp = merged.progressFor(levelId)!;
    expect(lp.status, LevelProgressStatus.completed);
    expect(lp.bestMoveCount, 2);
    expect(lp.bestTimeSeconds, 5);
    expect(lp.bestStars, StarRating.three);
  });

  test(
      'should_not_downgrade_status_when_remote_is_not_completed',
      () {
    // Arrange: local ya completado, remoto no completado.
    final local = PlayerProgress(
      playerId: const Identifier('u1'),
      levels: {
        levelId: const LevelProgress(levelId: levelId, status: LevelProgressStatus.completed),
      },
    );

    // Act
    final merged = local.mergeRemoteLevel(
      levelId: levelId,
      remoteBestMoveCount: null,
      remoteBestTimeSeconds: null,
      remoteCompleted: false,
    );

    // Assert: sigue completado.
    expect(merged.progressFor(levelId)!.status, LevelProgressStatus.completed);
  });
}
