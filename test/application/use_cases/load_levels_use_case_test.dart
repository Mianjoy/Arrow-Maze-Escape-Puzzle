import 'package:arrow_maze_escape_puzzle/application/use_cases/load_levels_use_case.dart';
import 'package:test/test.dart';

import '../support/fake_repositories.dart';

void main() {
  group('LoadLevelsUseCase', () {
    test('retorna todos los niveles del repositorio', () async {
      // Arrange
      final level = buildTestLevel();
      final useCase = LoadLevelsUseCase(levelRepository: FakeLevelRepository([level]));

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, [level]);
    });

    test('retorna una lista vacía cuando no hay niveles', () async {
      // Arrange
      final useCase = LoadLevelsUseCase(levelRepository: FakeLevelRepository());

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isEmpty);
    });
  });
}
