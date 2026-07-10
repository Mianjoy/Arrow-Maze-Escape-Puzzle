import 'package:arrow_maze_escape_puzzle/application/use_cases/load_levels_use_case.dart';
import 'package:test/test.dart';

import '../support/fake_repositories.dart';

void main() {
  group('LoadLevelsUseCase', () {
    test('should_return_all_levels_from_repository', () async {
      // Arrange
      final level = buildTestLevel();
      final useCase = LoadLevelsUseCase(levelRepository: FakeLevelRepository([level]));

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, [level]);
    });

    test('should_return_empty_list_when_repository_has_no_levels', () async {
      // Arrange
      final useCase = LoadLevelsUseCase(levelRepository: FakeLevelRepository());

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isEmpty);
    });
  });
}
