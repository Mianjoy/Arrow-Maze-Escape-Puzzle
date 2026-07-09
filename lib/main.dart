import 'package:flutter/material.dart';

import 'application/use_cases/fire_arrow_use_case.dart';
import 'application/use_cases/load_levels_use_case.dart';
import 'application/use_cases/start_game_use_case.dart';
import 'domain/domain.dart';
import 'infrastructure/game/in_memory_game_repository.dart';
import 'infrastructure/http/api_config.dart';
import 'infrastructure/http/level_api_client.dart';
import 'infrastructure/level/fallback_level_repository.dart';
import 'infrastructure/level/json_asset_level_repository.dart';
import 'infrastructure/level/remote_level_repository.dart';
import 'infrastructure/progress/in_memory_player_progress_repository.dart';
import 'presentation/game/game_controller.dart';
import 'presentation/game/game_screen.dart';
import 'presentation/level_select/level_select_controller.dart';
import 'presentation/level_select/level_select_screen.dart';

/// Punto de entrada de la aplicación móvil Arrow-Maze.
///
/// Para pruebas E2E contra solo la API (sin fallback a assets):
/// `flutter run --dart-define=ASSET_FALLBACK=false`
void main() {
  const fallbackToAssets = bool.fromEnvironment('ASSET_FALLBACK', defaultValue: true);
  runApp(ArrowMazeApp(container: AppContainer(fallbackToAssets: fallbackToAssets)));
}

/// Composition root de la app: el único lugar que sabe qué implementación
/// concreta satisface cada puerto de dominio/aplicación.
///
/// Por defecto carga niveles desde el backend (`RemoteLevelRepository`) con
/// respaldo en assets locales si la API no responde. Mismo rol que
/// `container.ts` en el backend.
class AppContainer {
  /// Construye el contenedor de dependencias de la aplicación.
  ///
  /// Parámetros opcionales para tests o configuración avanzada:
  /// - [levelRepository]: sustituye toda la cadena remota/fallback.
  /// - [apiConfig]: URL base del backend (ver [ApiConfig.fromEnvironment]).
  /// - [fallbackToAssets]: si es `true`, usa [JsonAssetLevelRepository] cuando
  ///   falle la API remota.
  AppContainer({
    ILevelRepository? levelRepository,
    IGameRepository? gameRepository,
    IPlayerProgressRepository? progressRepository,
    ApiConfig? apiConfig,
    bool fallbackToAssets = true,
  })  : levelRepository = levelRepository ??
            _buildLevelRepository(
              apiConfig: apiConfig ?? ApiConfig.fromEnvironment,
              fallbackToAssets: fallbackToAssets,
            ),
        gameRepository = gameRepository ?? InMemoryGameRepository(),
        progressRepository =
            progressRepository ?? InMemoryPlayerProgressRepository();

  /// Puerto de carga de niveles (remoto, con opcional fallback a assets).
  final ILevelRepository levelRepository;

  /// Puerto de persistencia de partidas en memoria.
  final IGameRepository gameRepository;

  /// Puerto de persistencia del progreso del jugador en memoria.
  final IPlayerProgressRepository progressRepository;

  /// Ensambla [ILevelRepository] remoto y, si aplica, decorador de respaldo.
  static ILevelRepository _buildLevelRepository({
    required ApiConfig apiConfig,
    required bool fallbackToAssets,
  }) {
    final remote = RemoteLevelRepository(
      apiClient: LevelApiClient(config: apiConfig),
    );

    if (!fallbackToAssets) {
      return remote;
    }

    return FallbackLevelRepository(
      primary: remote,
      fallback: JsonAssetLevelRepository(),
    );
  }

  /// Crea el controlador de la pantalla de selección de nivel.
  ///
  /// Inyecta [LoadLevelsUseCase] con el [levelRepository] configurado en este
  /// contenedor (API o assets según disponibilidad).
  LevelSelectController buildLevelSelectController() {
    return LevelSelectController(
      loadLevelsUseCase: LoadLevelsUseCase(levelRepository: levelRepository),
    );
  }

  /// Crea el controlador de la pantalla de juego.
  ///
  /// Inyecta los casos de uso de inicio de partida y disparo de flechas
  /// respaldados por [gameRepository].
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
