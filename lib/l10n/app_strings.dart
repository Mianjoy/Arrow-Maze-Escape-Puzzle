import 'package:flutter/material.dart';

/// Contrato de cadenas localizadas de la interfaz (español e inglés).
///
/// Expone textos de todas las pantallas obligatorias del enunciado académico.
abstract class AppStrings {
  /// Constructor const para permitir que las subclases (`AppStringsEn`,
  /// `AppStringsEs`) sean instancias `const`.
  const AppStrings();

  /// Obtiene las cadenas para el [locale] indicado (`en` o `es`).
  static AppStrings forLocale(Locale locale) {
    return locale.languageCode == 'es' ? const AppStringsEs() : const AppStringsEn();
  }

  /// Título de la aplicación.
  String get appTitle;

  /// Etiqueta del botón "Jugar" en la pantalla de inicio.
  String get homePlay;

  /// Etiqueta del botón "Ajustes" en la pantalla de inicio.
  String get homeSettings;

  /// Título de la pantalla de ajustes.
  String get settingsTitle;

  /// Etiqueta del interruptor de silenciar audio.
  String get settingsMute;

  /// Etiqueta del interruptor de silenciar todos los efectos de sonido
  /// (todo excepto la música de fondo).
  String get settingsMuteEffects;

  /// Etiqueta de la sección de idioma en ajustes.
  String get settingsLanguage;

  /// Etiqueta de la opción de idioma inglés.
  String get settingsLanguageEn;

  /// Etiqueta de la opción de idioma español.
  String get settingsLanguageEs;

  /// Título de la pantalla de selección de nivel.
  String get levelSelectTitle;

  /// Etiqueta que indica que un nivel está bloqueado.
  String get levelLocked;

  /// Etiqueta que indica que un nivel ya fue completado.
  String get levelCompleted;

  /// Etiqueta del contador de movimientos.
  String get movesLabel;

  /// Etiqueta del puntaje.
  String get scoreLabel;

  /// Tooltip del botón para mostrar la cuadrícula del tablero.
  String get showGridTooltip;

  /// Tooltip del botón para ocultar la cuadrícula del tablero.
  String get hideGridTooltip;

  /// Etiqueta del temporizador con [remaining] y [total] en formato `mm:ss`.
  String timeRemainingLabel(String remaining, String total);

  /// Título de la pantalla de victoria.
  String get victoryTitle;

  /// Mensaje de la pantalla de victoria.
  String get victoryMessage;

  /// Etiqueta del botón "Siguiente nivel".
  String get nextLevel;

  /// Título de la pantalla de derrota.
  String get defeatTitle;

  /// Mensaje de la pantalla de derrota.
  String get defeatMessage;

  /// Mensaje de derrota cuando se agotaron los movimientos permitidos.
  String get defeatMovesExceededMessage;

  /// Mensaje de derrota cuando se agotó el tiempo límite del nivel.
  String get defeatTimeExceededMessage;

  /// Etiqueta del botón "Reintentar".
  String get retry;

  /// Etiqueta del botón "Volver a niveles".
  String get backToLevels;

  /// Etiqueta de la pantalla/botón de clasificación (leaderboard).
  String get leaderboard;

  /// Mensaje de confirmación de progreso guardado.
  String get progressSaved;

  /// Mensaje de error al sincronizar el progreso.
  String get progressSyncFailed;

  /// Aviso de que se está jugando sin conexión y el progreso se sincronizará luego.
  String get offlinePlayNotice;

  /// Error de login: usuario o contraseña incorrectos.
  String get invalidCredentialsError;

  /// Error de registro: el nombre de usuario ya está en uso.
  String get usernameAlreadyExistsError;

  /// Error de red al intentar autenticarse (sin conexión, servidor caído).
  String get authConnectionError;

  /// Etiqueta del botón "Iniciar sesión".
  String get signIn;

  /// Etiqueta del botón "Cerrar sesión".
  String get signOut;

  /// Título de la pantalla de inicio de sesión.
  String get loginTitle;

  /// Título de la pantalla de registro.
  String get registerTitle;

  /// Etiqueta del campo de nombre de usuario.
  String get usernameLabel;

  /// Etiqueta del campo de contraseña (login).
  String get passwordLabel;

  /// Etiqueta del campo de contraseña con el mínimo de caracteres (registro).
  String get passwordMinLengthLabel;

  /// Error de validación: campo requerido.
  String get requiredFieldError;

  /// Error de validación: nombre de usuario con menos de 3 caracteres.
  String get minUsernameLengthError;

  /// Error de validación: contraseña con menos de 8 caracteres.
  String get minPasswordLengthError;

  /// Etiqueta del botón para crear una cuenta.
  String get createAccount;

  /// Enlace en la pantalla de registro para volver al login.
  String get alreadyHaveAccountSignIn;

  /// Etiqueta de dificultad, con [name] interpolado.
  String difficultyLabel(String name);

  /// Etiqueta de movimientos par, con [par] interpolado.
  String parMovesLabel(int par);

  /// Etiqueta de estrellas obtenidas, con [stars] interpolado.
  String starsLabel(int stars);

  /// Tooltip del botón para refrescar el catálogo de niveles.
  String get refreshLevelsTooltip;

  /// Notificación cuando el catálogo se actualizó con niveles nuevos.
  String levelsCatalogUpdated(int totalCount, int addedCount);

  /// Notificación cuando el catálogo ya estaba al día.
  String levelsRefreshedUpToDate(int totalCount);

  /// Notificación cuando falla la actualización del catálogo.
  String get levelsRefreshFailed;

  /// Mensaje cuando falla la carga inicial del catálogo de niveles.
  String get levelSelectLoadFailed;

  /// Mensaje cuando el catálogo de niveles está vacío.
  String get levelSelectNoLevels;

  /// Mensaje cuando un nivel no tiene entradas en la clasificación.
  String get leaderboardNoScores;

  /// Mensaje cuando falla la carga del ranking de un nivel.
  String get leaderboardLoadFailed;

  /// Subtítulo de una entrada del ranking: puntaje, movimientos y tiempo.
  String leaderboardEntrySubtitle({
    required int score,
    required int moves,
    required int timeInSeconds,
  });

  /// Mensaje cuando el hub de clasificación no tiene niveles disponibles.
  String get leaderboardHubNoLevels;

  /// Mensaje cuando falla la carga del hub de clasificación.
  String get leaderboardHubLoadFailed;
}

/// Cadenas en inglés (idioma por defecto).
class AppStringsEn extends AppStrings {
  /// Crea la instancia const de cadenas en inglés.
  const AppStringsEn();

  @override
  String get appTitle => 'Arrow Maze Escape';

  @override
  String get homePlay => 'Play';

  @override
  String get homeSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsMute => 'Mute background music';

  @override
  String get settingsMuteEffects => 'Mute all sound effects';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageEs => 'Spanish';

  @override
  String get levelSelectTitle => 'Select Level';

  @override
  String get levelLocked => 'Locked';

  @override
  String get levelCompleted => 'Completed';

  @override
  String get movesLabel => 'Moves';

  @override
  String get scoreLabel => 'Score';

  @override
  String get showGridTooltip => 'Show grid';

  @override
  String get hideGridTooltip => 'Hide grid';

  @override
  String timeRemainingLabel(String remaining, String total) => 'Time: $remaining / $total';

  @override
  String get victoryTitle => 'Level cleared!';

  @override
  String get victoryMessage => 'Great job! Your progress was saved.';

  @override
  String get nextLevel => 'Next level';

  @override
  String get defeatTitle => 'Level failed';

  @override
  String get defeatMessage => 'You ran out of moves or time. Try again!';

  @override
  String get defeatMovesExceededMessage =>
      'You have exceeded the maximum number of moves allowed. You lost!';

  @override
  String get defeatTimeExceededMessage =>
      'The level time limit ran out. You lost!';

  @override
  String get retry => 'Retry';

  @override
  String get backToLevels => 'Back to levels';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get progressSaved => 'Progress saved.';

  @override
  String get progressSyncFailed => 'Progress sync failed';

  @override
  String get offlinePlayNotice =>
      "You're currently playing offline. Your progress is saved on this device and "
      'will sync with the server once you have a connection or the server is available.';

  @override
  String get invalidCredentialsError => 'Incorrect username or password.';

  @override
  String get usernameAlreadyExistsError => 'That username is already taken.';

  @override
  String get authConnectionError => "Couldn't reach the server. Check your connection and try again.";

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get loginTitle => 'Arrow Maze — Login';

  @override
  String get registerTitle => 'Arrow Maze — Register';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordMinLengthLabel => 'Password (min 8)';

  @override
  String get requiredFieldError => 'Required';

  @override
  String get minUsernameLengthError => 'Min 3 characters';

  @override
  String get minPasswordLengthError => 'Min 8 characters';

  @override
  String get createAccount => 'Create account';

  @override
  String get alreadyHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String difficultyLabel(String name) => 'Difficulty: $name';

  @override
  String parMovesLabel(int par) => 'Par: $par moves';

  @override
  String starsLabel(int stars) => 'Stars: $stars';

  @override
  String get refreshLevelsTooltip => 'Refresh levels';

  @override
  String levelsCatalogUpdated(int totalCount, int addedCount) =>
      'Catalog updated: $totalCount levels ($addedCount new).';

  @override
  String levelsRefreshedUpToDate(int totalCount) =>
      'Catalog is up to date ($totalCount levels).';

  @override
  String get levelsRefreshFailed => 'Could not refresh the level catalog.';

  @override
  String get levelSelectLoadFailed => 'Could not load the level catalog. Try again later.';

  @override
  String get levelSelectNoLevels => 'No levels available.';

  @override
  String get leaderboardNoScores => 'No scores recorded for this level yet.';

  @override
  String get leaderboardLoadFailed => 'Could not load the leaderboard. Try again later.';

  @override
  String leaderboardEntrySubtitle({
    required int score,
    required int moves,
    required int timeInSeconds,
  }) =>
      'Score: $score · Moves: $moves · Time: ${timeInSeconds}s';

  @override
  String get leaderboardHubNoLevels => 'No levels available to show rankings.';

  @override
  String get leaderboardHubLoadFailed => 'Could not load levels for the leaderboard.';
}

/// Cadenas en español.
class AppStringsEs extends AppStrings {
  /// Crea la instancia const de cadenas en español.
  const AppStringsEs();

  @override
  String get appTitle => 'Arrow Maze Escape';

  @override
  String get homePlay => 'Jugar';

  @override
  String get homeSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsMute => 'Silenciar música de fondo';

  @override
  String get settingsMuteEffects => 'Silenciar todos los efectos de sonido';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageEn => 'Inglés';

  @override
  String get settingsLanguageEs => 'Español';

  @override
  String get levelSelectTitle => 'Seleccionar nivel';

  @override
  String get levelLocked => 'Bloqueado';

  @override
  String get levelCompleted => 'Completado';

  @override
  String get movesLabel => 'Movimientos';

  @override
  String get scoreLabel => 'Puntuación';

  @override
  String get showGridTooltip => 'Mostrar cuadrícula';

  @override
  String get hideGridTooltip => 'Ocultar cuadrícula';

  @override
  String timeRemainingLabel(String remaining, String total) => 'Tiempo: $remaining / $total';

  @override
  String get victoryTitle => '¡Nivel superado!';

  @override
  String get victoryMessage => '¡Bien hecho! Tu progreso fue guardado.';

  @override
  String get nextLevel => 'Siguiente nivel';

  @override
  String get defeatTitle => 'Nivel fallido';

  @override
  String get defeatMessage => 'Agotaste movimientos o tiempo. ¡Inténtalo de nuevo!';

  @override
  String get defeatMovesExceededMessage =>
      'Has superado el número máximo de movimientos permitidos. ¡Has perdido!';

  @override
  String get defeatTimeExceededMessage =>
      'Se agotó el tiempo límite del nivel. ¡Has perdido!';

  @override
  String get retry => 'Reintentar';

  @override
  String get backToLevels => 'Volver a niveles';

  @override
  String get leaderboard => 'Clasificación';

  @override
  String get progressSaved => 'Progreso guardado.';

  @override
  String get progressSyncFailed => 'Error al sincronizar progreso';

  @override
  String get offlinePlayNotice =>
      'Actualmente te encuentras jugando sin conexión. Tu progreso se guarda en este '
      'dispositivo y se sincronizará con el servidor cuando tengas conexión o el '
      'servidor esté disponible.';

  @override
  String get invalidCredentialsError => 'Usuario o contraseña incorrectos.';

  @override
  String get usernameAlreadyExistsError => 'Ese nombre de usuario ya está en uso.';

  @override
  String get authConnectionError => 'No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get loginTitle => 'Arrow Maze — Iniciar sesión';

  @override
  String get registerTitle => 'Arrow Maze — Registro';

  @override
  String get usernameLabel => 'Usuario';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordMinLengthLabel => 'Contraseña (mín. 8)';

  @override
  String get requiredFieldError => 'Requerido';

  @override
  String get minUsernameLengthError => 'Mínimo 3 caracteres';

  @override
  String get minPasswordLengthError => 'Mínimo 8 caracteres';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get alreadyHaveAccountSignIn => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String difficultyLabel(String name) => 'Dificultad: $name';

  @override
  String parMovesLabel(int par) => 'Par: $par movimientos';

  @override
  String starsLabel(int stars) => 'Estrellas: $stars';

  @override
  String get refreshLevelsTooltip => 'Actualizar niveles';

  @override
  String levelsCatalogUpdated(int totalCount, int addedCount) =>
      'Catálogo actualizado: $totalCount niveles ($addedCount nuevo${addedCount == 1 ? '' : 's'}).';

  @override
  String levelsRefreshedUpToDate(int totalCount) =>
      'El catálogo ya está al día ($totalCount niveles).';

  @override
  String get levelsRefreshFailed => 'No se pudo actualizar el catálogo de niveles.';

  @override
  String get levelSelectLoadFailed => 'No se pudo cargar el catálogo de niveles. Intenta más tarde.';

  @override
  String get levelSelectNoLevels => 'No hay niveles disponibles.';

  @override
  String get leaderboardNoScores => 'Aún no hay registros en este nivel.';

  @override
  String get leaderboardLoadFailed => 'No se pudo cargar la clasificación. Intenta más tarde.';

  @override
  String leaderboardEntrySubtitle({
    required int score,
    required int moves,
    required int timeInSeconds,
  }) =>
      'Puntaje: $score · Movimientos: $moves · Tiempo: ${timeInSeconds}s';

  @override
  String get leaderboardHubNoLevels => 'No hay niveles disponibles para mostrar clasificaciones.';

  @override
  String get leaderboardHubLoadFailed => 'No se pudieron cargar los niveles para la clasificación.';
}

/// Provee [AppStrings] a descendientes del árbol de widgets vía `of(context)`.
class AppStringsScope extends InheritedWidget {
  /// Envuelve [child] con las cadenas [strings] activas.
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  /// Cadenas localizadas vigentes.
  final AppStrings strings;

  /// Resuelve las cadenas del contexto; lanza si falta el scope.
  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    assert(scope != null, 'AppStringsScope not found in widget tree');
    return scope!.strings;
  }

  /// Indica si las cadenas cambiaron y los descendientes deben reconstruirse.
  @override
  bool updateShouldNotify(AppStringsScope oldWidget) => strings != oldWidget.strings;
}
