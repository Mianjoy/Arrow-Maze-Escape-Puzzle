import 'package:arrow_maze_escape_puzzle/application/use_cases/refresh_levels_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

import '../support/fake_repositories.dart';

/// Simula un backend que expone más niveles tras invalidar la caché del cliente.
class StagedFakeLevelRepository implements ILevelRepository {
  var _fetchCount = 0;
  var invalidateCalls = 0;

  @override
  void invalidateCache() {
    invalidateCalls += 1;
  }

  @override
  Future<List<Level>> findAll() async {
    _fetchCount += 1;
    if (_fetchCount == 1) {
      return [buildTestLevel(id: 'level-01')];
    }
    return [
      buildTestLevel(id: 'level-01'),
      buildTestLevel(id: 'level-02'),
    ];
  }

  @override
  Future<Level?> findById(Identifier id) async => null;
}

void main() {
  group('RefreshLevelsUseCase', () {
    test('should_report_new_levels_after_cache_invalidation', () async {
      final repo = StagedFakeLevelRepository();
      final useCase = RefreshLevelsUseCase(levelRepository: repo);

      final result = await useCase.execute();

      expect(repo.invalidateCalls, 1);
      expect(result.previousCount, 1);
      expect(result.newCount, 2);
      expect(result.addedCount, 1);
      expect(result.hasNewLevels, isTrue);
    });

    test('should_report_up_to_date_when_catalog_unchanged', () async {
      final repo = FakeLevelRepository([
        buildTestLevel(id: 'level-01'),
      ]);
      final useCase = RefreshLevelsUseCase(levelRepository: repo);

      final result = await useCase.execute();

      expect(result.addedCount, 0);
      expect(result.hasNewLevels, isFalse);
      expect(result.newCount, 1);
    });
  });
}
