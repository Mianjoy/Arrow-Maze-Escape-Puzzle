import 'dart:convert';
import 'dart:io';

import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

/// Valida que los archivos JSON de niveles empaquetados (`assets/levels/`)
/// parseen correctamente y sean resolubles a través de [LevelFactory].
///
/// Los widget tests usan un `FakeLevelRepository`, así que sin esta prueba
/// el contenido real de los niveles (y su solvabilidad, que `LevelFactory`
/// exige) nunca se ejercitaría automáticamente. Lee los archivos con
/// `dart:io` en vez de `rootBundle` para no depender del binding de Flutter.
void main() {
  const factory = LevelFactory(
    shortestPathCalculator: ShortestPathCalculator(
      movementEngine: ArrowMovementEngine(
        collisionValidator: CollisionValidator(),
      ),
    ),
  );

  final assetPaths = [
    'assets/levels/level_01.json',
    'assets/levels/level_02.json',
    'assets/levels/level_03.json',
  ];

  group('Bundled level assets', () {
    for (final path in assetPaths) {
      test('$path parses and is solvable via LevelFactory', () {
        // Arrange
        final raw = File(path).readAsStringSync();
        final json = jsonDecode(raw) as Map<String, dynamic>;

        // Act
        final level = factory.fromJson(json);

        // Assert
        expect(level.id.value, isNotEmpty);
        expect(level.optimalMoves, greaterThan(0));
        expect(level.optimalMoves, lessThanOrEqualTo(level.parMoves));
      });
    }

    test('all bundled asset ids are unique', () {
      // Arrange & Act
      final ids = assetPaths.map((path) {
        final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        return factory.fromJson(json).id.value;
      }).toList();

      // Assert
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
