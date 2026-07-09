import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'application/models/auth_session.dart';
import 'application/ports/i_app_settings.dart';
import 'application/ports/i_audio_service.dart';
import 'application/ports/i_token_storage.dart';
import 'application/use_cases/ensure_initial_progress_use_case.dart';
import 'application/use_cases/fire_arrow_use_case.dart';
import 'application/use_cases/get_leaderboard_use_case.dart';
import 'application/use_cases/get_player_progress_use_case.dart';
import 'application/use_cases/load_levels_use_case.dart';
import 'application/use_cases/login_user_use_case.dart';
import 'application/use_cases/logout_user_use_case.dart';
import 'application/use_cases/record_victory_use_case.dart';
import 'application/use_cases/register_user_use_case.dart';
import 'application/use_cases/restore_auth_session_use_case.dart';
import 'application/use_cases/start_game_use_case.dart';
import 'domain/domain.dart';
import 'infrastructure/audio/app_audio_service.dart';
import 'infrastructure/audio/no_op_audio_service.dart';
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
import 'infrastructure/progress/shared_preferences_player_progress_repository.dart';
import 'infrastructure/settings/in_memory_app_settings.dart';
import 'infrastructure/settings/shared_preferences_app_settings.dart';
import 'l10n/app_strings.dart';
import 'presentation/auth/auth_session_controller.dart';
import 'presentation/auth/login_controller.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_controller.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/game/game_controller.dart';
import 'presentation/game/game_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/leaderboard/leaderboard_controller.dart';
import 'presentation/leaderboard/leaderboard_screen.dart';
import 'presentation/level_select/level_select_controller.dart';
import 'presentation/level_select/level_select_screen.dart';
import 'presentation/result/defeat_screen.dart';
import 'presentation/result/result_screen_args.dart';
import 'presentation/result/victory_screen.dart';
import 'presentation/settings/app_settings_controller.dart';
import 'presentation/settings/settings_screen.dart';

/// Punto de entrada: inicializa preferencias, progreso local y composition root.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const fallbackToAssets = bool.fromEnvironment('ASSET_FALLBACK', defaultValue: true);
  final tokenStorage = await SharedPreferencesTokenStorage.create();
  final appSettings = await SharedPreferencesAppSettings.create();
  final progressRepository = await SharedPreferencesPlayerProgressRepository.create();

  final container = AppContainer(
    tokenStorage: tokenStorage,
    appSettings: appSettings,
    progressRepository: progressRepository,
    fallbackToAssets: fallbackToAssets,
  );
  await container.initialize();

  runApp(ArrowMazeApp(container: container));
}

/// Composition root: ensambla HTTP, progreso local, audio, settings y controladores.
class AppContainer {
  /// Construye el contenedor; parámetros opcionales para tests.
  AppContainer({
    ILevelRepository? levelRepository,
    IGameRepository? gameRepository,
    IPlayerProgressRepository? progressRepository,
    ITokenStorage? tokenStorage,
    IAppSettings? appSettings,
    IAudioService? audioService,
    ApiConfig? apiConfig,
    http.Client? httpClient,
    bool fallbackToAssets = true,
    AuthSession? initialAuthSession,
    bool enableProgressSync = true,
  })  : apiConfig = apiConfig ?? ApiConfig.fromEnvironment,
        _httpClient = httpClient ?? http.Client(),
        tokenStorage = tokenStorage ?? InMemoryTokenStorage(),
        appSettings = appSettings ?? InMemoryAppSettings(),
        levelRepository = levelRepository ??
            _buildLevelRepository(
              apiConfig: apiConfig ?? ApiConfig.fromEnvironment,
              fallbackToAssets: fallbackToAssets,
              httpClient: httpClient,
            ),
        gameRepository = gameRepository ?? InMemoryGameRepository(),
        progressRepository = progressRepository ?? InMemoryPlayerProgressRepository(),
        _enableProgressSync = enableProgressSync {
    authApiClient = AuthApiClient(config: this.apiConfig, httpClient: _httpClient);
    progressApiClient = ProgressApiClient(config: this.apiConfig, httpClient: _httpClient);
    leaderboardApiClient = LeaderboardApiClient(config: this.apiConfig, httpClient: _httpClient);

    appSettingsController = AppSettingsController(settings: this.appSettings);
    audioService = audioService ?? AppAudioService(settings: this.appSettings);

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

    getPlayerProgressUseCase = GetPlayerProgressUseCase(progressRepository: this.progressRepository);
    ensureInitialProgressUseCase = EnsureInitialProgressUseCase(
      levelRepository: this.levelRepository,
      progressRepository: this.progressRepository,
    );

    recordVictoryUseCase = _enableProgressSync
        ? RecordVictoryUseCase(
            progressRepository: this.progressRepository,
            levelRepository: this.levelRepository,
            progressApiClient: progressApiClient,
          )
        : null;
  }

  final ApiConfig apiConfig;
  final http.Client _httpClient;
  final bool _enableProgressSync;

  final ITokenStorage tokenStorage;
  final IAppSettings appSettings;

  late final AuthApiClient authApiClient;
  late final ProgressApiClient progressApiClient;
  late final LeaderboardApiClient leaderboardApiClient;
  late final AppSettingsController appSettingsController;
  late final IAudioService audioService;
  late final AuthSessionController authSessionController;
  late final GetPlayerProgressUseCase getPlayerProgressUseCase;
  late final EnsureInitialProgressUseCase ensureInitialProgressUseCase;

  /// Caso de uso de victoria + sync; `null` si [enableProgressSync] es false.
  ///
  /// `late` porque se asigna en el cuerpo del constructor (depende de
  /// [progressApiClient], ensamblado ahí mismo), no en la lista de
  /// inicialización.
  late final RecordVictoryUseCase? recordVictoryUseCase;

  final ILevelRepository levelRepository;
  final IGameRepository gameRepository;
  final IPlayerProgressRepository progressRepository;

  /// Restaura sesión y preferencias; inicia música si no está silenciada.
  Future<void> initialize() async {
    await appSettingsController.load();
    if (authSessionController.session == null) {
      await authSessionController.restoreSession();
    }
    await audioService.startBackgroundMusic();
  }

  static ILevelRepository _buildLevelRepository({
    required ApiConfig apiConfig,
    required bool fallbackToAssets,
    http.Client? httpClient,
  }) {
    final remote = RemoteLevelRepository(
      apiClient: LevelApiClient(config: apiConfig, httpClient: httpClient),
    );
    if (!fallbackToAssets) return remote;
    return FallbackLevelRepository(primary: remote, fallback: JsonAssetLevelRepository());
  }

  /// Controlador de selección de nivel para el jugador autenticado.
  LevelSelectController buildLevelSelectController() {
    final playerId = authSessionController.session?.playerId ?? const Identifier('local-player');
    return LevelSelectController(
      loadLevelsUseCase: LoadLevelsUseCase(levelRepository: levelRepository),
      ensureInitialProgressUseCase: ensureInitialProgressUseCase,
      getPlayerProgressUseCase: getPlayerProgressUseCase,
      playerId: playerId,
    );
  }

  LoginController buildLoginController() =>
      LoginController(authSessionController: authSessionController);

  RegisterController buildRegisterController() =>
      RegisterController(authSessionController: authSessionController);

  LeaderboardController buildLeaderboardController() => LeaderboardController(
        getLeaderboardUseCase: GetLeaderboardUseCase(leaderboardApiClient: leaderboardApiClient),
      );

  GameController buildGameController() => GameController(
        startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
        fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
        authSessionController: authSessionController,
        audioService: audioService,
        recordVictoryUseCase: recordVictoryUseCase,
      );
}

/// Raíz de la app con localización, rutas y música de fondo.
class ArrowMazeApp extends StatefulWidget {
  const ArrowMazeApp({super.key, required this.container});

  final AppContainer container;

  @override
  State<ArrowMazeApp> createState() => _ArrowMazeAppState();
}

class _ArrowMazeAppState extends State<ArrowMazeApp> {
  @override
  void initState() {
    super.initState();
    widget.container.appSettingsController.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.container.appSettingsController.removeListener(_onSettingsChanged);
    super.dispose();
  }

  /// Reconstruye el árbol cuando cambian idioma o mute.
  void _onSettingsChanged() {
    setState(() {});
    final muted = widget.container.appSettingsController.isMuted;
    if (muted) {
      widget.container.audioService.stopBackgroundMusic();
    } else {
      widget.container.audioService.startBackgroundMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.container.appSettingsController.locale;
    final strings = AppStrings.forLocale(locale);

    return AppStringsScope(
      strings: strings,
      child: MaterialApp(
        title: strings.appTitle,
        locale: locale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/home',
        onGenerateRoute: (settings) => _onGenerateRoute(settings),
      ),
    );
  }

  /// Resuelve rutas de inicio, ajustes, auth, niveles, juego y resultados.
  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final container = widget.container;

    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(
          builder: (_) => HomeScreen(authSessionController: container.authSessionController),
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => SettingsScreen(settingsController: container.appSettingsController),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => LoginScreen(controller: container.buildLoginController()),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(controller: container.buildRegisterController()),
        );
      case '/levels':
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
      case '/victory':
        final args = settings.arguments as VictoryScreenArgs;
        return MaterialPageRoute(builder: (_) => VictoryScreen(args: args));
      case '/defeat':
        final navArgs = settings.arguments as DefeatNavigationArgs;
        return MaterialPageRoute(
          builder: (_) => DefeatScreen(
            args: navArgs.screenArgs,
            gameController: navArgs.gameController,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => HomeScreen(authSessionController: container.authSessionController),
        );
    }
  }
}
