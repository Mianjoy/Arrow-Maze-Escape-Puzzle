/// Estado de una partida en curso o finalizada.
enum GameStatus {
  /// Partida creada pero aún no iniciada.
  ready,

  /// Partida en progreso.
  inProgress,

  /// Partida en pausa; no acepta movimientos hasta reanudarse.
  ///
  /// Portado desde el dominio en español (`EstatusJuego.pausado` en la rama
  /// `Integracion`) durante la fusión de dominio de Sprint 1.
  paused,

  /// El jugador completó el nivel (todas las flechas extraídas).
  won,

  /// El jugador agotó vidas, tiempo u otra condición de derrota.
  lost,

  /// Partida abandonada por el jugador.
  abandoned,
}
