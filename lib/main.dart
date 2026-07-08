import 'package:flutter/material.dart';

import 'application/use_cases/fire_arrow_use_case.dart';
import 'application/use_cases/load_levels_use_case.dart';
import 'application/use_cases/start_game_use_case.dart';
import 'domain/domain.dart';
import 'infrastructure/game/in_memory_game_repository.dart';
import 'infrastructure/level/json_asset_level_repository.dart';
import 'infrastructure/progress/in_memory_player_progress_repository.dart';
import 'presentation/game/game_controller.dart';
import 'presentation/game/game_screen.dart';
import 'presentation/level_select/level_select_controller.dart';
import 'presentation/level_select/level_select_screen.dart';

/// Punto de entrada de la aplicación móvil Arrow-Maze.
void main() {
  runApp(ArrowMazeApp(container: AppContainer()));
}

/// Composition root de la app: el único lugar que sabe qué implementación
/// concreta satisface cada puerto de dominio/aplicación (hoy: repositorios
/// en memoria/assets locales; mañana podría intercambiarse por SQLite/Hive
/// o un cliente HTTP contra el backend sin tocar casos de uso ni pantallas).
///
/// Mismo rol que `container.ts` en el backend.
class AppContainer {
  /// Construye el contenedor con las implementaciones concretas por defecto
  /// (assets locales + repositorios en memoria).
  AppContainer()
      : levelRepository = JsonAssetLevelRepository(),
        gameRepository = InMemoryGameRepository(),
        progressRepository = InMemoryPlayerProgressRepository();

  /// Puerto de carga de niveles.
  final ILevelRepository levelRepository;

  /// Puerto de persistencia de partidas.
  final IGameRepository gameRepository;

  /// Puerto de persistencia del progreso del jugador.
  final IPlayerProgressRepository progressRepository;

  /// Crea el controlador de la pantalla de selección de nivel.
  LevelSelectController buildLevelSelectController() {
    return LevelSelectController(
      loadLevelsUseCase: LoadLevelsUseCase(levelRepository: levelRepository),
    );
  }

  /// Crea el controlador de la pantalla de juego.
  GameController buildGameController() {
    return GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
    );
  }
}

/// Widget raíz de la aplicación Arrow-Maze.
///
/// Pantallas de inicio/ajustes, audio e i18n quedan para un follow-up;
/// esta primera versión enruta directo a selección de nivel → juego.
class ArrowMazeApp extends StatelessWidget {
  /// Crea la app con el [container] de composición ya construido.
  const ArrowMazeApp({super.key, required this.container});

  /// Contenedor de dependencias de la aplicación.
  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow-Maze Escape',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/game':
            final level = settings.arguments as Level;
            return MaterialPageRoute(
              builder: (_) => GameScreen(
                controller: container.buildGameController(),
                level: level,
              ),
            );
          case '/':
          default:
            return MaterialPageRoute(
              builder: (_) => LevelSelectScreen(
                controller: container.buildLevelSelectController(),
              ),
            );
        }
      },
    );
  }
}
