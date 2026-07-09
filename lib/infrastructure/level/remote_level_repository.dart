import '../../domain/domain.dart';
import '../../interface_adapters/level_dto_mapper.dart';
import '../http/level_api_client.dart';
import 'level_repository_exception.dart';

/// Implementación de [ILevelRepository] que consume el catálogo del backend.
///
/// Flujo:
/// 1. [LevelApiClient] obtiene JSON wire-format (`StructuredLevelJsonDto`).
/// 2. [LevelDtoMapper] traduce cada entrada a un agregado [Level] de dominio.
/// 3. Se cachea el resultado en memoria para evitar peticiones repetidas.
///
/// Requiere el backend en ejecución con seed (`GET /levels` poblado).
/// Para desarrollo offline, usar [FallbackLevelRepository] en el composition root.
class RemoteLevelRepository implements ILevelRepository {
  /// Crea el repositorio con cliente HTTP y mapper inyectables.
  RemoteLevelRepository({
    required LevelApiClient apiClient,
    LevelDtoMapper? mapper,
  })  : _apiClient = apiClient,
        _mapper = mapper ?? const LevelDtoMapper();

  final LevelApiClient _apiClient;
  final LevelDtoMapper _mapper;

  List<Level>? _cache;

  @override
  Future<List<Level>> findAll() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }

    final payloads = await _apiClient.fetchAllLevels();
    final levels = <Level>[];

    for (final json in payloads) {
      try {
        levels.add(_mapper.fromJson(json));
      } on DomainException catch (error) {
        throw LevelRepositoryException(
          'Level ${json['id'] ?? '?'} rejected by domain mapper: $error',
        );
      }
    }

    levels.sort(
      (a, b) => (a.levelNumber ?? 0).compareTo(b.levelNumber ?? 0),
    );
    _cache = List.unmodifiable(levels);
    return _cache!;
  }

  @override
  Future<Level?> findById(Identifier id) async {
    final cached = _cache;
    if (cached != null) {
      return _findInList(cached, id);
    }

    final payload = await _apiClient.fetchLevelById(id.value);
    if (payload == null) {
      return null;
    }

    try {
      return _mapper.fromJson(payload);
    } on DomainException catch (error) {
      throw LevelRepositoryException(
        'Level ${id.value} rejected by domain mapper: $error',
      );
    }
  }

  /// Busca un nivel en una lista ya materializada por [findAll].
  Level? _findInList(List<Level> levels, Identifier id) {
    for (final level in levels) {
      if (level.id == id) {
        return level;
      }
    }
    return null;
  }
}
