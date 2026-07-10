import 'package:arrow_maze_escape_puzzle/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_app_factory.dart';
import 'support/playable_level_helper.dart';
import 'support/seed_catalog_fixture.dart';

/// Pruebas E2E del catálogo remoto simulado (15 niveles, sin fallback a assets).
void main() {
  group('E2E — remote catalog (simulated GET /levels)', () {
    late AppContainer container;

    setUp(() {
      container = E2eAppFactory.createWithFullSeedCatalog();
    });

    test('should_load_exactly_15_seed_levels', () async {
      final levels = await container.levelRepository.findAll();
      expect(levels.length, kSeedCatalogExpectedCount);
    });

    test('should_order_levels_by_levelNumber', () async {
      final levels = await container.levelRepository.findAll();
      for (var i = 0; i < levels.length; i++) {
        expect(levels[i].levelNumber, i + 1);
      }
    });

    test('should_map_each_fixture_entry_to_domain_without_error', () {
      for (final json in SeedCatalogFixture.load()) {
        expect(
          () => PlayableLevelHelper.mapWireLevel(json),
          returnsNormally,
          reason: 'Mapper failed for ${json['id']}',
        );
      }
    });
  });
}
