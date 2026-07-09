import 'package:flutter/material.dart';

import 'application/use_cases/fire_arrow_use_case.dart';
import 'application/use_cases/get_leaderboard_use_case.dart';
import 'application/use_cases/load_levels_use_case.dart';
import 'application/use_cases/login_user_use_case.dart';
import 'application/use_cases/logout_user_use_case.dart';
import 'application/use_cases/record_victory_use_case.dart';
import 'application/use_cases/register_user_use_case.dart';
import 'application/use_cases/restore_auth_session_use_case.dart';
import 'application/use_cases/start_game_use_case.dart';
import 'application/models/auth_session.dart';
import 'application/ports/i_token_storage.dart';
import 'domain/domain.dart';
import 'infrastructure/auth/in_memory_token_storage.dart';
import 'infrastructure/auth/shared_preferences_token_storage.dart';
import 'infrastructure/game/in_memory_game_repository.dart';
import 'infrastructure/http/api_config.dart';
import 'infrastructure/http/auth_api_client.dart';
import 'infrastructure/http/leaderboard_api_client.dart';
import 'infrastructure/http/level_api_client.dart';
import 'infrastructure/http/progress_api_client.dart';
import 'infrastructure/level/fallback_level_repository.dart';
import 'infrastructure/level/json_asset_level_repository.dart';
import 'infrastructure/level/remote_level_repository.dart';
import 'infrastructure/progress/in_memory_player_progress_repository.dart';
import 'presentation/auth/auth_session_controller.dart';
import 'presentation/auth/login_controller.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_controller.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/game/game_controller.dart';
import 'presentation/game/game_screen.dart';
import 'presentation/leaderboard/leaderboard_controller.dart';
import 'presentation/leaderboard/leaderboard_screen.dart';
import 'presentation/level_select/level_select_controller.dart';
import 'presentation/level_select/level_select_screen.dart';
import 'package:http/http.dart' as http;

/// Punto de entrada de la aplicación móvil Arrow-Maze.
///
/// Para pruebas E2E contra solo la API (sin fallback a assets):
/// `flutter run --dart-define=ASSET_FALLBACK=false`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const fallbackToAssets = bool.fromEnvironment('ASSET_FALLBACK', defaultValue: true);
  final tokenStorage = await _createDefaultTokenStorage();
  final container = AppContainer(
    tokenStorage: tokenStorage,
    fallbackToAssets: fallbackToAssets,
  );
  await container.initialize();

  runApp(ArrowMazeApp(container: container));
}

/// Crea almacenamiento de token: SharedPreferences en app real, inyectable en tests.
Future<ITokenStorage> _createDefaultTokenStorage() async {
  return SharedPreferencesTokenStorage.create();
}

/// Composition root de la app: ensambla clientes HTTP, casos de uso y controladores.
///
/// Equivalente a `container.ts` en el backend; único lugar con implementaciones concretas.
class AppContainer {
  /// Construye el contenedor con dependencias opcionales para tests.
  AppContainer({
    ILevelRepository? levelRepository,
    IGameRepository? gameRepository,
    IPlayerProgressRepository? progressRepository,
    ITokenStorage? tokenStorage,
    ApiConfig? apiConfig,
    http.Client? httpClient,
    bool fallbackToAssets = true,
    AuthSession? initialAuthSession,
    bool enableProgressSync = true,
  })  : apiConfig = apiConfig ?? ApiConfig.fromEnvironment,
        _httpClient = httpClient ?? http.Client(),
        tokenStorage = tokenStorage ?? InMemoryTokenStorage(),
        levelRepository = levelRepository ??
            _buildLevelRepository(
              apiConfig: apiConfig ?? ApiConfig.fromEnvironment,
              fallbackToAssets: fallbackToAssets,
              httpClient: httpClient,
            ),
        gameRepository = gameRepository ?? InMemoryGameRepository(),
        progressRepository =
            progressRepository ?? InMemoryPlayerProgressRepository(),
        _enableProgressSync = enableProgressSync {
    authApiClient = AuthApiClient(config: this.apiConfig, httpClient: _httpClient);
    progressApiClient = ProgressApiClient(config: this.apiConfig, httpClient: _httpClient);
    leaderboardApiClient =
        LeaderboardApiClient(config: this.apiConfig, httpClient: _httpClient);

    authSessionController = AuthSessionController(
      loginUserUseCase: LoginUserUseCase(
        authApiClient: authApiClient,
        tokenStorage: this.tokenStorage,
      ),
      registerUserUseCase: RegisterUserUseCase(
        authApiClient: authApiClient,
        tokenStorage: this.tokenStorage,
      ),
      logoutUserUseCase: LogoutUserUseCase(tokenStorage: this.tokenStorage),
      restoreAuthSessionUseCase: RestoreAuthSessionUseCase(tokenStorage: this.tokenStorage),
      initialSession: initialAuthSession,
    );

    recordVictoryUseCase = _enableProgressSync
        ? RecordVictoryUseCase(
            progressRepository: this.progressRepository,
            progressApiClient: progressApiClient,
          )
        : null;
  }

  /// URL base del backend.
  final ApiConfig apiConfig;

  final http.Client _httpClient;
  final bool _enableProgressSync;

  /// Almacén local del JWT.
  final ITokenStorage tokenStorage;

  /// Cliente HTTP de autenticación.
  late final AuthApiClient authApiClient;

  /// Cliente HTTP de sincronización de progreso.
  late final ProgressApiClient progressApiClient;

  /// Cliente HTTP de leaderboard.
  late final LeaderboardApiClient leaderboardApiClient;

  /// Controlador global de sesión.
  late final AuthSessionController authSessionController;

  /// Caso de uso de victoria + sync; `null` si [enableProgressSync] es false.
  ///
  /// `late` porque se asigna en el cuerpo del constructor (depende de
  /// [progressApiClient], ensamblado ahí mismo), no en la lista de
  /// inicialización.
  late final RecordVictoryUseCase? recordVictoryUseCase;

  /// Puerto de carga de niveles.
  final ILevelRepository levelRepository;

  /// Puerto de persistencia de partidas.
  final IGameRepository gameRepository;

  /// Puerto de progreso local del jugador.
  final IPlayerProgressRepository progressRepository;

  /// Restaura sesión desde almacenamiento (llamar una vez al arrancar).
  Future<void> initialize() async {
    if (authSessionController.session == null) {
      await authSessionController.restoreSession();
    }
  }

  /// Ensambla [ILevelRepository] remoto con opcional fallback a assets.
  static ILevelRepository _buildLevelRepository({
    required ApiConfig apiConfig,
    required bool fallbackToAssets,
    http.Client? httpClient,
  }) {
    final remote = RemoteLevelRepository(
      apiClient: LevelApiClient(config: apiConfig, httpClient: httpClient),
    );

    if (!fallbackToAssets) {
      return remote;
    }

    return FallbackLevelRepository(
      primary: remote,
      fallback: JsonAssetLevelRepository(),
    );
  }

  /// Crea el controlador de selección de nivel.
  LevelSelectController buildLevelSelectController() {
    return LevelSelectController(
      loadLevelsUseCase: LoadLevelsUseCase(levelRepository: levelRepository),
    );
  }

  /// Crea el controlador de login.
  LoginController buildLoginController() {
    return LoginController(authSessionController: authSessionController);
  }

  /// Crea el controlador de registro.
  RegisterController buildRegisterController() {
    return RegisterController(authSessionController: authSessionController);
  }

  /// Crea el controlador de leaderboard.
  LeaderboardController buildLeaderboardController() {
    return LeaderboardController(
      getLeaderboardUseCase: GetLeaderboardUseCase(
        leaderboardApiClient: leaderboardApiClient,
      ),
    );
  }

  /// Crea el controlador de juego con el jugador de la sesión activa.
  GameController buildGameController() {
    return GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: authSessionController,
      recordVictoryUseCase: recordVictoryUseCase,
    );
  }
}

/// Widget raíz: rutas de auth, selección de nivel, juego y leaderboard.
class ArrowMazeApp extends StatelessWidget {
  /// Crea la app con el [container] de composición ya inicializado.
  const ArrowMazeApp({super.key, required this.container});

  /// Contenedor de dependencias de la aplicación.
  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    final initialRoute = container.authSessionController.isAuthenticated ? '/' : '/login';

    return MaterialApp(
      title: 'Arrow-Maze Escape',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (_) => LoginScreen(controller: container.buildLoginController()),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (_) => RegisterScreen(controller: container.buildRegisterController()),
            );
          case '/leaderboard':
            final levelId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => LeaderboardScreen(
                controller: container.buildLeaderboardController(),
                levelId: levelId,
              ),
            );
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
            if (!container.authSessionController.isAuthenticated) {
              return MaterialPageRoute(
                builder: (_) => LoginScreen(controller: container.buildLoginController()),
              );
            }
            return MaterialPageRoute(
              builder: (_) => LevelSelectScreen(
                controller: container.buildLevelSelectController(),
                authSessionController: container.authSessionController,
              ),
            );
        }
      },
    );
  }
}
