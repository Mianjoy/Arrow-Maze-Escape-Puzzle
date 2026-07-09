import '../../domain/domain.dart';

/// Decorador de [ILevelRepository] que intenta la fuente [primary] y, si falla,
/// delega en [fallback].
///
/// Útil cuando el backend no está disponible (desarrollo offline, CI sin servidor)
/// sin cambiar casos de uso ni pantallas. El composition root (`AppContainer`)
/// puede activarlo con `fallbackToAssets: true`.
class FallbackLevelRepository implements ILevelRepository {
  /// Crea el decorador con repositorio remoto [primary] y respaldo [fallback].
  const FallbackLevelRepository({
    required ILevelRepository primary,
    required ILevelRepository fallback,
  })  : _primary = primary,
        _fallback = fallback;

  final ILevelRepository _primary;
  final ILevelRepository _fallback;

  @override
  Future<List<Level>> findAll() async {
    try {
      return await _primary.findAll();
    } catch (_) {
      return _fallback.findAll();
    }
  }

  @override
  Future<Level?> findById(Identifier id) async {
    try {
      final level = await _primary.findById(id);
      if (level != null) {
        return level;
      }
    } catch (_) {
      return _fallback.findById(id);
    }

    return _fallback.findById(id);
  }
}
