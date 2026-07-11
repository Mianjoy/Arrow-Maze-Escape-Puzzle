import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'application/models/auth_session.dart';
import 'application/ports/i_app_settings.dart';
import 'application/ports/i_audio_service.dart';
import 'application/ports/i_pending_sync_repository.dart';
import 'application/ports/i_token_storage.dart';
import 'application/ports/i_use_case_logger.dart';
import 'application/use_cases/ensure_initial_progress_use_case.dart';
import 'application/use_cases/fire_arrow_use_case.dart';
import 'application/use_cases/get_leaderboard_use_case.dart';
import 'application/use_cases/get_player_progress_use_case.dart';
import 'application/use_cases/load_levels_use_case.dart';
import 'application/use_cases/logging_fire_arrow_use_case_decorator.dart';
import 'application/use_cases/login_user_use_case.dart';
import 'application/use_cases/logout_user_use_case.dart';
import 'application/use_cases/pull_remote_progress_use_case.dart';
import 'application/use_cases/record_victory_use_case.dart';
import 'application/use_cases/refresh_levels_use_case.dart';
import 'application/use_cases/register_user_use_case.dart';
import 'application/use_cases/restore_auth_session_use_case.dart';
import 'application/use_cases/start_game_use_case.dart';
import 'application/use_cases/sync_pending_progress_use_case.dart';
import 'domain/domain.dart';
import 'infrastructure/audio/app_audio_service.dart';
import 'infrastructure/auth/in_memory_token_storage.dart';
import 'infrastructure/auth/shared_preferences_token_storage.dart';
import 'infrastructure/game/in_memory_game_repository.dart';
import 'infrastructure/http/api_config.dart';
import 'infrastructure/http/auth_api_client.dart';
import 'infrastructure/http/leaderboard_api_client.dart';
import 'infrastructure/http/level_api_client.dart';
import 'infrastructure/http/progress_api_client.dart';
import 'infrastructure/level/cached_level_repository.dart';
import 'infrastructure/logging/console_use_case_logger.dart';
import 'infrastructure/progress/in_memory_pending_sync_repository.dart';
import 'infrastructure/progress/in_memory_player_progress_repository.dart';
import 'infrastructure/progress/shared_preferences_pending_sync_repository.dart';
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
import 'presentation/leaderboard/leaderboard_route_args.dart';
import 'presentation/leaderboard/leaderboard_hub_screen.dart';
import 'presentation/leaderboard/leaderboard_screen.dart';
import 'presentation/level_select/level_select_controller.dart';
import 'presentation/level_select/level_select_screen.dart';
import 'presentation/result/defeat_screen.dart';
import 'presentation/result/result_screen_args.dart';
import 'presentation/result/victory_screen.dart';
import 'presentation/settings/app_settings_controller.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/navigation/app_route_observer.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/audio_scope.dart';
import 'presentation/widgets/phone_frame.dart';

/// Punto de entrada: inicializa preferencias, progreso local y composition root.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final tokenStorage = await SharedPreferencesTokenStorage.create();
  final appSettings = await SharedPreferencesAppSettings.create();
  final progressRepository = await SharedPreferencesPlayerProgressRepository.create();

  final container = AppContainer(
    prefs: prefs,
    tokenStorage: tokenStorage,
    appSettings: appSettings,
    progressRepository: progressRepository,
  );
  await container.initialize();

  runApp(ArrowMazeApp(container: container));
}

/// Composition root: ensambla HTTP, progreso local, audio, settings y controladores.
class AppContainer {
  /// Construye el contenedor; parámetros opcionales para tests.
  AppContainer({
    SharedPreferences? prefs,
    ILevelRepository? levelRepository,
    IGameRepository? gameRepository,
    IPlayerProgressRepository? progressRepository,
    IPendingSyncRepository? pendingSyncRepository,
    ITokenStorage? tokenStorage,
    IAppSettings? appSettings,
    IAudioService? audioService,
    ApiConfig? apiConfig,
    http.Client? httpClient,
    IUseCaseLogger? useCaseLogger,
    AuthSession? initialAuthSession,
    bool enableProgressSync = true,
  })  : apiConfig = apiConfig ?? ApiConfig.fromEnvironment,
        _httpClient = httpClient ?? http.Client(),
        useCaseLogger = useCaseLogger ?? ConsoleUseCaseLogger(),
        tokenStorage = tokenStorage ?? InMemoryTokenStorage(),
        appSettings = appSettings ?? InMemoryAppSettings(),
        levelRepository = levelRepository ??
            _buildLevelRepository(
              apiConfig: apiConfig ?? ApiConfig.fromEnvironment,
              prefs: _requirePrefs(prefs),
              httpClient: httpClient,
            ),
        gameRepository = gameRepository ?? InMemoryGameRepository(),
        progressRepository = progressRepository ?? InMemoryPlayerProgressRepository(),
        pendingSyncRepository = pendingSyncRepository ??
            (prefs != null
                ? SharedPreferencesPendingSyncRepository(prefs: prefs)
                : InMemoryPendingSyncRepository()),
        _enableProgressSync = enableProgressSync {
    authApiClient = AuthApiClient(config: this.apiConfig, httpClient: _httpClient);
    progressApiClient = ProgressApiClient(config: this.apiConfig, httpClient: _httpClient);
    leaderboardApiClient = LeaderboardApiClient(config: this.apiConfig, httpClient: _httpClient);

    appSettingsController = AppSettingsController(settings: this.appSettings);
    this.audioService = audioService ?? AppAudioService(settings: this.appSettings);

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
            pendingSyncRepository: this.pendingSyncRepository,
          )
        : null;

    syncPendingProgressUseCase = _enableProgressSync
        ? SyncPendingProgressUseCase(
            pendingSyncRepository: this.pendingSyncRepository,
            progressApiClient: progressApiClient,
          )
        : null;

    pullRemoteProgressUseCase = _enableProgressSync
        ? PullRemoteProgressUseCase(
            progressApiClient: progressApiClient,
            progressRepository: this.progressRepository,
            levelRepository: this.levelRepository,
          )
        : null;
  }

  /// Configuración del cliente HTTP hacia el backend.
  final ApiConfig apiConfig;
  final http.Client _httpClient;
  final bool _enableProgressSync;

  /// Aspecto AOP de logging/trazabilidad para casos de uso (ver
  /// [LoggingFireArrowUseCaseDecorator]).
  final IUseCaseLogger useCaseLogger;

  /// Almacenamiento del token de sesión.
  final ITokenStorage tokenStorage;

  /// Preferencias de la app (idioma, mute).
  final IAppSettings appSettings;

  /// Cliente HTTP de autenticación.
  late final AuthApiClient authApiClient;

  /// Cliente HTTP de sincronización de progreso.
  late final ProgressApiClient progressApiClient;

  /// Cliente HTTP de la tabla de clasificación.
  late final LeaderboardApiClient leaderboardApiClient;

  /// Controlador de ajustes de la app.
  late final AppSettingsController appSettingsController;

  /// Servicio de audio (efectos y música de fondo).
  late final IAudioService audioService;

  /// Controlador de la sesión de autenticación.
  late final AuthSessionController authSessionController;

  /// Caso de uso para consultar el progreso del jugador.
  late final GetPlayerProgressUseCase getPlayerProgressUseCase;

  /// Caso de uso para asegurar el progreso inicial de un jugador.
  late final EnsureInitialProgressUseCase ensureInitialProgressUseCase;

  /// Caso de uso de victoria + sync; `null` si [enableProgressSync] es false.
  ///
  /// `late` porque se asigna en el cuerpo del constructor (depende de
  /// [progressApiClient], ensamblado ahí mismo), no en la lista de
  /// inicialización.
  late final RecordVictoryUseCase? recordVictoryUseCase;

  /// Caso de uso que reintenta sincronizaciones pendientes; `null` si
  /// [enableProgressSync] es false. Mismo motivo `late` que arriba.
  late final SyncPendingProgressUseCase? syncPendingProgressUseCase;

  /// Caso de uso que descarga y fusiona el progreso remoto; `null` si
  /// [enableProgressSync] es false. Mismo motivo `late` que arriba.
  late final PullRemoteProgressUseCase? pullRemoteProgressUseCase;

  /// Puerto de carga de niveles.
  final ILevelRepository levelRepository;

  /// Puerto de persistencia de partidas.
  final IGameRepository gameRepository;

  /// Puerto de persistencia del progreso del jugador.
  final IPlayerProgressRepository progressRepository;

  /// Puerto de la cola de sincronizaciones de progreso pendientes.
  final IPendingSyncRepository pendingSyncRepository;

  /// Restaura sesión y preferencias; inicia música si no está silenciada.
  ///
  /// `startBackgroundMusic` NO se espera (`unawaited`): en Flutter Web, los
  /// navegadores bloquean `AudioContext` hasta que hay un gesto real del
  /// usuario (política de autoplay), así que su `Future` puede no resolver
  /// nunca hasta el primer clic. Si `initialize()` lo esperara, `runApp()`
  /// jamás se llamaría y la app quedaría en blanco para siempre.
  Future<void> initialize() async {
    await appSettingsController.load();
    if (authSessionController.session == null) {
      await authSessionController.restoreSession();
    }
    unawaited(audioService.startBackgroundMusic());
  }

  static ILevelRepository _buildLevelRepository({
    required ApiConfig apiConfig,
    required SharedPreferences prefs,
    http.Client? httpClient,
  }) {
    return CachedLevelRepository(
      apiClient: LevelApiClient(config: apiConfig, httpClient: httpClient),
      prefs: prefs,
    );
  }

  /// Exige [prefs] cuando no se inyecta un [ILevelRepository] ya construido:
  /// [CachedLevelRepository] necesita `SharedPreferences` para su caché
  /// offline, y no se puede resolver `SharedPreferences.getInstance()` de
  /// forma síncrona dentro de una lista de inicialización.
  static SharedPreferences _requirePrefs(SharedPreferences? prefs) {
    if (prefs == null) {
      throw ArgumentError(
        'AppContainer requires `prefs` when `levelRepository` is not provided.',
      );
    }
    return prefs;
  }

  /// Controlador de selección de nivel para el jugador autenticado.
  LevelSelectController buildLevelSelectController() {
    final playerId = authSessionController.session?.playerId ?? const Identifier('local-player');
    return LevelSelectController(
      loadLevelsUseCase: LoadLevelsUseCase(levelRepository: levelRepository),
      refreshLevelsUseCase: RefreshLevelsUseCase(levelRepository: levelRepository),
      ensureInitialProgressUseCase: ensureInitialProgressUseCase,
      getPlayerProgressUseCase: getPlayerProgressUseCase,
      playerId: playerId,
      syncPendingProgressUseCase: syncPendingProgressUseCase,
      pullRemoteProgressUseCase: pullRemoteProgressUseCase,
      session: authSessionController.session,
    );
  }

  /// Crea el controlador de la pantalla de inicio de sesión.
  LoginController buildLoginController() =>
      LoginController(authSessionController: authSessionController);

  /// Crea el controlador de la pantalla de registro.
  RegisterController buildRegisterController() =>
      RegisterController(authSessionController: authSessionController);

  /// Crea el controlador de la pantalla de clasificación.
  LeaderboardController buildLeaderboardController() => LeaderboardController(
        getLeaderboardUseCase: GetLeaderboardUseCase(leaderboardApiClient: leaderboardApiClient),
      );

  /// Crea el controlador de la pantalla de juego.
  ///
  /// `fireArrowUseCase` se envuelve con [LoggingFireArrowUseCaseDecorator]
  /// (aspecto AOP de logging/trazabilidad): registra el estado del tablero
  /// antes/después de cada disparo sin que `FireArrowUseCase` ni
  /// `GameController` conozcan el logger.
  GameController buildGameController() => GameController(
        startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
        fireArrowUseCase: LoggingFireArrowUseCaseDecorator(
          inner: FireArrowUseCase(gameRepository: gameRepository),
          logger: useCaseLogger,
        ),
        authSessionController: authSessionController,
        audioService: audioService,
        recordVictoryUseCase: recordVictoryUseCase,
      );
}

/// Raíz de la app con localización, rutas y música de fondo.
class ArrowMazeApp extends StatefulWidget {
  /// Crea la app con el [container] de composición ya construido.
  const ArrowMazeApp({super.key, required this.container});

  /// Contenedor de dependencias de la aplicación.
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

  /// Reconstruye el árbol cuando cambian idioma o mute de música de fondo.
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

    return PhoneFrame(
      child: AppStringsScope(
        strings: strings,
        child: AudioScope(
          audioService: widget.container.audioService,
          child: MaterialApp(
          title: strings.appTitle,
          locale: locale,
          theme: AppTheme.build(),
          initialRoute: '/home',
          navigatorObservers: [appRouteObserver],
          builder: (context, child) {
            return child ?? const SizedBox.shrink();
          },
          onGenerateRoute: (settings) => _onGenerateRoute(settings),
          ),
        ),
      ),
    );
  }

  /// Resuelve rutas de inicio, ajustes, auth, niveles, juego y resultados.
  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final container = widget.container;

    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeScreen(authSessionController: container.authSessionController),
        );
      case '/settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SettingsScreen(settingsController: container.appSettingsController),
        );
      case '/login':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LoginScreen(controller: container.buildLoginController()),
        );
      case '/register':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RegisterScreen(controller: container.buildRegisterController()),
        );
      case '/levels':
        if (!container.authSessionController.isAuthenticated) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => LoginScreen(controller: container.buildLoginController()),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LevelSelectScreen(
            controller: container.buildLevelSelectController(),
            authSessionController: container.authSessionController,
          ),
        );
      case '/leaderboard':
        final args = settings.arguments;
        if (args is LeaderboardRouteArgs || args is String) {
          final levelId = args is LeaderboardRouteArgs ? args.levelId : args as String;
          final levelTitle = args is LeaderboardRouteArgs ? args.levelTitle : null;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => LeaderboardScreen(
              controller: container.buildLeaderboardController(),
              levelId: levelId,
              levelTitle: levelTitle,
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LeaderboardHubScreen(
            loadLevelsUseCase: LoadLevelsUseCase(levelRepository: container.levelRepository),
          ),
        );
      case '/game':
        final level = settings.arguments as Level;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => GameScreen(
            controller: container.buildGameController(),
            level: level,
          ),
        );
      case '/victory':
        final args = settings.arguments as VictoryScreenArgs;
        return MaterialPageRoute(settings: settings, builder: (_) => VictoryScreen(args: args));
      case '/defeat':
        final navArgs = settings.arguments as DefeatNavigationArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DefeatScreen(
            args: navArgs.screenArgs,
            gameController: navArgs.gameController,
          ),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeScreen(authSessionController: container.authSessionController),
        );
    }
  }
}
