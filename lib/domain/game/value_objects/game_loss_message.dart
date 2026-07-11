/// Motivo por el que una partida terminó en derrota.
enum GameLossReason {
  /// Se agotaron los movimientos permitidos ([Level.parMoves]).
  movesExceeded,

  /// Se agotó el tiempo límite del nivel.
  timeExceeded,
}

/// Mensaje de derrota estandarizado para la capa de presentación.
///
/// Transporta únicamente el [reason]; el texto localizado se resuelve en la
/// capa de presentación vía `AppStrings`, para que el idioma mostrado
/// dependa del idioma seleccionado en la app y no quede fijo en el idioma en
/// el que se escribió el dominio.
class GameLossMessage {
  /// Crea un mensaje de derrota con el [reason] indicado.
  const GameLossMessage(this.reason);

  /// Se agotaron los movimientos permitidos ([Level.parMoves]).
  static const movesExceeded = GameLossMessage(GameLossReason.movesExceeded);

  /// Se agotó el tiempo límite del nivel.
  static const timeExceeded = GameLossMessage(GameLossReason.timeExceeded);

  /// Motivo de la derrota.
  final GameLossReason reason;
}
