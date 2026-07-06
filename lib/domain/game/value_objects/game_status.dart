/// Estado de una partida en curso o finalizada.
enum GameStatus {
  /// Partida creada pero aún no iniciada.
  ready,

  /// Partida en progreso.
  inProgress,

  /// El jugador completó el nivel (todas las flechas extraídas).
  won,

  /// El jugador agotó vidas, tiempo u otra condición de derrota.
  lost,

  /// Partida abandonada por el jugador.
  abandoned,
}
