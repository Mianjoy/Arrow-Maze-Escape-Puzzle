import 'package:flutter/foundation.dart';

import '../../application/models/leaderboard_entry.dart';
import '../../application/use_cases/get_leaderboard_use_case.dart';

/// Controlador de la pantalla de leaderboard por nivel.
///
/// Carga el ranking remoto vía [GetLeaderboardUseCase] y expone la lista
/// o errores de red al widget.
class LeaderboardController extends ChangeNotifier {
  /// Crea el controlador con el caso de uso de consulta de ranking.
  LeaderboardController({required GetLeaderboardUseCase getLeaderboardUseCase})
      : _getLeaderboardUseCase = getLeaderboardUseCase;

  final GetLeaderboardUseCase _getLeaderboardUseCase;

  List<LeaderboardEntry> _entries = [];
  bool _isLoading = false;
  Object? _error;

  /// Entradas del ranking cargadas para el nivel actual.
  List<LeaderboardEntry> get entries => _entries;

  /// Indica si se está consultando la API.
  bool get isLoading => _isLoading;

  /// Error de la última carga, o `null` si fue exitosa.
  Object? get error => _error;

  /// Obtiene el top de jugadores para [levelId].
  Future<void> load(String levelId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _getLeaderboardUseCase.execute(levelId: levelId);
    } catch (error) {
      _entries = [];
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
