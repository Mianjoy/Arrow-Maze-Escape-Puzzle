import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/domain.dart';
import '../../interface_adapters/level_dto_mapper.dart';
import '../http/level_api_client.dart';

/// Implementación de [ILevelRepository] respaldada por el catálogo remoto,
/// con persistencia local write-through en [SharedPreferences].
///
/// Flujo:
/// 1. Intenta `GET /levels` vía [LevelApiClient] (JSON crudo, sin traducir).
/// 2. Si tiene éxito, guarda ese JSON en disco y lo traduce a [Level] con
///    [LevelDtoMapper].
/// 3. Si falla (sin red, timeout, error del servidor), recurre a la última
///    copia guardada en disco; si tampoco existe, relanza el error original.
///
/// Esto permite jugar sin conexión con el último catálogo descargado, sin
/// depender de niveles empaquetados como assets de la app.
class CachedLevelRepository implements ILevelRepository {
  /// Crea el repositorio con cliente HTTP, preferencias y mapper inyectables.
  CachedLevelRepository({
    required LevelApiClient apiClient,
    required SharedPreferences prefs,
    LevelDtoMapper? mapper,
  })  : _apiClient = apiClient,
        _prefs = prefs,
        _mapper = mapper ?? const LevelDtoMapper();

  final LevelApiClient _apiClient;
  final SharedPreferences _prefs;
  final LevelDtoMapper _mapper;

  static const _cacheKey = 'cached_levels_json';

  List<Level>? _cache;

  /// Lista todos los niveles (memoria, red o última copia en disco).
  @override
  Future<List<Level>> findAll() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }

    List<Map<String, dynamic>> payloads;
    try {
      payloads = await _apiClient.fetchAllLevels();
      await _prefs.setString(_cacheKey, jsonEncode(payloads));
    } catch (error) {
      final stored = _readStoredPayloads();
      if (stored == null) rethrow;
      payloads = stored;
    }

    final levels = _mapAndSort(payloads);
    _cache = levels;
    return levels;
  }

  /// Obtiene un nivel por [id] desde el catálogo ya cargado.
  @override
  Future<Level?> findById(Identifier id) async {
    final levels = await findAll();
    for (final level in levels) {
      if (level.id == id) return level;
    }
    return null;
  }

  /// Descarta la caché en memoria para forzar una nueva descarga.
  @override
  void invalidateCache() {
    _cache = null;
  }

  /// Lee el catálogo cacheado en disco, o `null` si nunca se guardó ninguno.
  List<Map<String, dynamic>>? _readStoredPayloads() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Traduce los payloads crudos a [Level] y los ordena por número de nivel.
  ///
  /// Un nivel que el mapper no pueda traducir (p. ej. un valor de
  /// `difficulty` que esta versión de la app todavía no reconoce) se omite
  /// en vez de tumbar el catálogo completo — un solo nivel inesperado del
  /// servidor no debe dejar a nadie sin poder jugar ninguno de los demás.
  List<Level> _mapAndSort(List<Map<String, dynamic>> payloads) {
    final levels = <Level>[];
    for (final payload in payloads) {
      try {
        levels.add(_mapper.fromJson(payload));
      } catch (error) {
        developer.log(
          'Skipping level ${payload['id'] ?? '?'}: $error',
          name: 'CachedLevelRepository',
          level: 900,
        );
      }
    }
    levels.sort((a, b) => (a.levelNumber ?? 0).compareTo(b.levelNumber ?? 0));
    return List.unmodifiable(levels);
  }
}
