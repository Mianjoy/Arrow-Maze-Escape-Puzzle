/// Resultado de refrescar el catálogo de niveles desde el servidor.
class LevelCatalogRefreshResult {
  /// Crea el resultado con conteos antes y después del refresh.
  const LevelCatalogRefreshResult({
    required this.previousCount,
    required this.newCount,
    required this.addedCount,
  });

  /// Cantidad de niveles antes de invalidar la caché.
  final int previousCount;

  /// Cantidad de niveles tras la nueva descarga.
  final int newCount;

  /// Niveles cuyo `id` no estaba en el catálogo previo.
  final int addedCount;

  /// `true` si se detectaron niveles nuevos respecto a la caché anterior.
  bool get hasNewLevels => addedCount > 0;
}
