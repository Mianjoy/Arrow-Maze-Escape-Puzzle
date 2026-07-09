import '../../domain/domain.dart';
import '../game/game_controller.dart';

/// Argumentos de navegación hacia la pantalla de victoria.
class VictoryScreenArgs {
  /// Crea los argumentos con la partida ganada y metadatos de sync.
  const VictoryScreenArgs({
    required this.game,
    this.nextLevel,
    this.syncError,
  });

  /// Partida finalizada en estado ganado.
  final Game game;

  /// Siguiente nivel desbloqueado en la secuencia, si existe.
  final Level? nextLevel;

  /// Error de sincronización remota, si ocurrió.
  final Object? syncError;
}

/// Argumentos de la pantalla de derrota (solo datos de dominio).
class DefeatScreenArgs {
  /// Crea los argumentos con la partida perdida.
  const DefeatScreenArgs({required this.game});

  /// Partida finalizada en estado perdido.
  final Game game;
}

/// Argumentos de ruta hacia derrota incluyendo el controlador para reintentar.
class DefeatNavigationArgs {
  /// Empaqueta [screenArgs] y el [gameController] activo.
  const DefeatNavigationArgs({
    required this.screenArgs,
    required this.gameController,
  });

  /// Datos de la partida perdida.
  final DefeatScreenArgs screenArgs;

  /// Controlador de la partida en curso.
  final GameController gameController;
}
