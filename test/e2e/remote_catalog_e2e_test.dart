import 'package:arrow_maze_escape_puzzle/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_app_factory.dart';
import 'support/playable_level_helper.dart';
import 'support/seed_catalog_fixture.dart';

/// Pruebas E2E del catálogo remoto simulado (15 niveles, sin fallback a assets).
void main() {
  group('E2E — catálogo remoto (GET /levels simulado)', () {
    late AppContainer container;

    setUp(() {
      container = E2eAppFactory.createWithFullSeedCatalog();
    });

    test('carga exactamente 15 niveles del seed', () async {
      final levels = await container.levelRepository.findAll();
      expect(levels.length, kSeedCatalogExpectedCount);
    });

    test('los niveles están ordenados por levelNumber', () async {
      final levels = await container.levelRepository.findAll();
      for (var i = 0; i < levels.length; i++) {
        expect(levels[i].levelNumber, i + 1);
      }
    });

    test('cada entrada del fixture mapea a dominio sin error', () {
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
