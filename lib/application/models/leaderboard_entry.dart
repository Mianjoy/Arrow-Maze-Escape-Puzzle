/// Entrada de clasificación devuelta por `GET /leaderboard/:levelId`.
///
/// Modelo de lectura de la capa de aplicación; no pertenece al dominio del
/// juego porque el ranking es una proyección del backend.
class LeaderboardEntry {
  /// Crea una entrada con las métricas públicas del jugador en un nivel.
  const LeaderboardEntry({
    required this.username,
    required this.highScore,
    required this.minMoves,
    required this.minTimeInSeconds,
  });

  /// Nombre del jugador en el ranking.
  final String username;

  /// Mejor puntuación registrada para el nivel.
  final int highScore;

  /// Menor cantidad de movimientos con la que completó el nivel.
  final int minMoves;

  /// Menor tiempo en segundos registrado al completar el nivel.
  final int minTimeInSeconds;
}
