import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/level/fallback_level_repository.dart';
import 'package:test/test.dart';

/// Repositorio falso que lanza o devuelve datos fijos para pruebas del decorador.
class _StubLevelRepository implements ILevelRepository {
  _StubLevelRepository({
    this.findAllResult,
    this.findAllError,
    this.findByIdResult,
    this.findByIdError,
  });

  final List<Level>? findAllResult;
  final Object? findAllError;
  final Level? findByIdResult;
  final Object? findByIdError;

  @override
  Future<List<Level>> findAll() async {
    if (findAllError != null) throw findAllError!;
    return findAllResult ?? [];
  }

  @override
  Future<Level?> findById(Identifier id) async {
    if (findByIdError != null) throw findByIdError!;
    return findByIdResult;
  }
}

void main() {
  group('FallbackLevelRepository', () {
    test('findAll usa fallback cuando primary falla', () async {
      final primary = _StubLevelRepository(findAllError: Exception('offline'));
      final fallback = _StubLevelRepository(findAllResult: []);

      final repo = FallbackLevelRepository(primary: primary, fallback: fallback);
      expect(await repo.findAll(), isEmpty);
    });

    test('findById usa fallback cuando primary lanza', () async {
      final primary = _StubLevelRepository(findByIdError: Exception('offline'));
      final fallback = _StubLevelRepository(findByIdResult: null);

      final repo = FallbackLevelRepository(primary: primary, fallback: fallback);
      expect(await repo.findById(const Identifier('x')), isNull);
    });
  });
}
