import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/playable_level_helper.dart';
import 'support/seed_catalog_fixture.dart';

/// Valida jugabilidad de dominio para cada nivel del seed (wire → partida).
void main() {
  group('E2E — wire-format playability (domain)', () {
    test('should_start_all_seed_levels_with_arrows_on_board', () async {
      for (final json in SeedCatalogFixture.load()) {
        final level = PlayableLevelHelper.mapWireLevel(json);
        final game = await PlayableLevelHelper.startGame(level);

        expect(game.isPlayable, isTrue, reason: json['id'] as String);
        expect(game.board.arrows, isNotEmpty, reason: json['id'] as String);
      }
    });

    // should_materialize_walls_from_wire_format_for_level_04 se retiró junto
    // con level-04 (violaba la regla de mínimo 1 celda de cuerpo por
    // flecha). Ningún nivel semilla actual (01/09/12/15) tiene `walls`; la
    // cobertura de materialización de muros vuelve cuando el equipo diseñe
    // manualmente un nivel de reemplazo con `walls`.

    test('should_win_level_12_with_single_shot_tutorial', () async {
      final level = PlayableLevelHelper.mapWireLevel(SeedCatalogFixture.levelById('level-12'));
      final game = await PlayableLevelHelper.startGame(level);
      final after = await PlayableLevelHelper.tapCell(
        game,
        const Position(row: 0, column: 3),
      );

      expect(after.isWon, isTrue);
    });

    test('should_win_level_15_with_greedy_shots_expert', () async {
      final level = PlayableLevelHelper.mapWireLevel(SeedCatalogFixture.levelById('level-15'));
      final game = await PlayableLevelHelper.startGame(level);
      final solved = await PlayableLevelHelper.solveGreedy(game);

      expect(solved.isWon, isTrue, reason: 'Greedy solver should clear expert chain level');
    });

    test('should_lose_level_09_when_par_moves_exhausted_without_clearing', () async {
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
