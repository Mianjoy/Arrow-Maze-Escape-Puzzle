/// Argumentos de navegación hacia el ranking de un nivel concreto.
class LeaderboardRouteArgs {
  /// Crea los argumentos con [levelId] obligatorio y [levelTitle] opcional.
  const LeaderboardRouteArgs({
    required this.levelId,
    this.levelTitle,
  });

  /// Identificador técnico del nivel (API `GET /leaderboard/:levelId`).
  final String levelId;

  /// Nombre visible en la UI; si falta, la pantalla usa [levelId].
  final String? levelTitle;
}
