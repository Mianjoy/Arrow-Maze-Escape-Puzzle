import '../../domain/domain.dart';
import '../models/level_catalog_refresh_result.dart';

/// Caso de uso: forzar descarga del catálogo remoto invalidando la caché local.
///
/// Usado desde la pantalla de selección de nivel cuando el backend pudo haber
/// incorporado nuevos puzzles (p. ej. tras hot-reload del directorio `levels/`).
class RefreshLevelsUseCase {
  /// Crea el caso de uso con el repositorio de niveles.
  const RefreshLevelsUseCase({required ILevelRepository levelRepository})
      : _levelRepository = levelRepository;

  final ILevelRepository _levelRepository;

  /// Invalida la caché, vuelve a pedir `GET /levels` y compara conteos.
  Future<LevelCatalogRefreshResult> execute() async {
    final before = await _levelRepository.findAll();
    final beforeIds = before.map((level) => level.id.value).toSet();

    _levelRepository.invalidateCache();

    final after = await _levelRepository.findAll();
    final afterIds = after.map((level) => level.id.value).toSet();

    return LevelCatalogRefreshResult(
      previousCount: before.length,
      newCount: after.length,
      addedCount: afterIds.difference(beforeIds).length,
    );
  }
}
