import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/playable_level_helper.dart';
import 'support/seed_catalog_fixture.dart';

/// Valida jugabilidad de dominio para cada nivel del seed (wire → partida).
void main() {
  group('E2E — jugabilidad wire-format (dominio)', () {
    test('los 15 niveles inician partida con flechas en el tablero', () async {
      for (final json in SeedCatalogFixture.load()) {
        final level = PlayableLevelHelper.mapWireLevel(json);
        final game = await PlayableLevelHelper.startGame(level);

        expect(game.isPlayable, isTrue, reason: json['id'] as String);
        expect(game.board.arrows, isNotEmpty, reason: json['id'] as String);
      }
    });

    test('level-04 materializa muros del wire format', () {
      final json = SeedCatalogFixture.levelById('level-04');
      final level = PlayableLevelHelper.mapWireLevel(json);
      expect(PlayableLevelHelper.countWalls(level), 1);
    });

    test('level-02 se gana con un disparo (tutorial)', () async {
      final level = PlayableLevelHelper.mapWireLevel(SeedCatalogFixture.levelById('level-02'));
      final game = await PlayableLevelHelper.startGame(level);
      final after = await PlayableLevelHelper.tapCell(
        game,
        const Position(row: 0, column: 0),
      );

      expect(after.isWon, isTrue);
    });

    test('level-08 se gana con disparos greedy', () async {
      final level = PlayableLevelHelper.mapWireLevel(SeedCatalogFixture.levelById('level-08'));
      final game = await PlayableLevelHelper.startGame(level);
      final solved = await PlayableLevelHelper.solveGreedy(game);

      expect(solved.isWon, isTrue);
    });

    test('level-15 se gana con disparos greedy (EXPERT)', () async {
      final level = PlayableLevelHelper.mapWireLevel(SeedCatalogFixture.levelById('level-15'));
      final game = await PlayableLevelHelper.startGame(level);
      final solved = await PlayableLevelHelper.solveGreedy(game);

      expect(solved.isWon, isTrue, reason: 'Greedy solver should clear expert chain level');
    });

    test('level-09 derrota al agotar parMoves sin completar', () async {
      final level = PlayableLevelHelper.mapWireLevel(SeedCatalogFixture.levelById('level-09'));
      var game = await PlayableLevelHelper.startGame(level);

      for (var i = 0; i < level.parMoves; i++) {
        game = await PlayableLevelHelper.tapCell(
          game,
          const Position(row: 0, column: 2),
        );
        if (!game.isPlayable) {
          break;
        }
      }

      expect(game.isLost, isTrue);
    });
  });
}
