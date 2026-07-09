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

  String get appTitle;
  String get homePlay;
  String get homeSettings;
  String get settingsTitle;
  String get settingsMute;
  String get settingsLanguage;
  String get settingsLanguageEn;
  String get settingsLanguageEs;
  String get levelSelectTitle;
  String get levelLocked;
  String get levelCompleted;
  String get movesLabel;
  String get scoreLabel;
  String get victoryTitle;
  String get victoryMessage;
  String get nextLevel;
  String get defeatTitle;
  String get defeatMessage;
  String get retry;
  String get backToLevels;
  String get leaderboard;
  String get progressSaved;
  String get progressSyncFailed;
  String get signIn;
  String get signOut;
  String difficultyLabel(String name);
  String parMovesLabel(int par);
  String starsLabel(int stars);
}

/// Cadenas en inglés (idioma por defecto).
class AppStringsEn extends AppStrings {
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
  String get settingsMute => 'Mute audio';

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
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String difficultyLabel(String name) => 'Difficulty: $name';

  @override
  String parMovesLabel(int par) => 'Par: $par moves';

  @override
  String starsLabel(int stars) => 'Stars: $stars';
}

/// Cadenas en español.
class AppStringsEs extends AppStrings {
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
  String get settingsMute => 'Silenciar audio';

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
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String difficultyLabel(String name) => 'Dificultad: $name';

  @override
  String parMovesLabel(int par) => 'Par: $par movimientos';

  @override
  String starsLabel(int stars) => 'Estrellas: $stars';
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

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) => strings != oldWidget.strings;
}
