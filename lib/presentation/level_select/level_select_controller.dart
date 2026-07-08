import 'package:flutter/foundation.dart';

import '../../application/use_cases/load_levels_use_case.dart';
import '../../domain/domain.dart';

/// Controlador (ChangeNotifier) de la pantalla de selección de nivel.
///
/// Orquesta [LoadLevelsUseCase] y expone su resultado a la UI de forma
/// observable, sin que el widget tenga que conocer el caso de uso.
class LevelSelectController extends ChangeNotifier {
  /// Crea el controlador con el caso de uso de carga de niveles.
  LevelSelectController({required LoadLevelsUseCase loadLevelsUseCase})
      : _loadLevelsUseCase = loadLevelsUseCase;

  final LoadLevelsUseCase _loadLevelsUseCase;

  List<Level> _levels = const [];
  bool _isLoading = false;
  Object? _error;

  /// Niveles cargados (vacío mientras carga o ante error).
  List<Level> get levels => _levels;

  /// Indica si la carga está en curso.
  bool get isLoading => _isLoading;

  /// Error de la última carga, o `null` si fue exitosa.
  Object? get error => _error;

  /// Carga los niveles disponibles y notifica a los oyentes.
  Future<void> loadLevels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _levels = await _loadLevelsUseCase.execute();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
