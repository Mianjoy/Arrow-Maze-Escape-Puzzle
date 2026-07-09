import '../../domain/domain.dart';

/// Caso de uso: cargar todos los niveles disponibles.
///
/// Depende únicamente de [ILevelRepository] (puerto de dominio) — no sabe
/// si los niveles vienen de assets locales, una API remota, etc.
class LoadLevelsUseCase {
  /// Crea el caso de uso con el [levelRepository] del que cargar los niveles.
  const LoadLevelsUseCase({required ILevelRepository levelRepository})
      : _levelRepository = levelRepository;

  final ILevelRepository _levelRepository;

  /// Retorna todos los niveles disponibles.
  Future<List<Level>> execute() {
    return _levelRepository.findAll();
  }
}
