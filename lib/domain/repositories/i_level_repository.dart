import '../level/aggregates/level.dart';
import '../shared/value_objects/identifier.dart';

/// Contrato de persistencia/carga para definiciones de nivel ([Level]).
///
/// La implementación concreta (assets locales, backend remoto, etc.)
/// pertenece a la capa de infraestructura.
abstract interface class ILevelRepository {
  /// Lista todos los niveles disponibles.
  Future<List<Level>> findAll();

  /// Obtiene un nivel por [id] o `null` si no existe.
  Future<Level?> findById(Identifier id);

  /// Descarta la caché en memoria para forzar una nueva descarga en el próximo [findAll].
  void invalidateCache();
}
