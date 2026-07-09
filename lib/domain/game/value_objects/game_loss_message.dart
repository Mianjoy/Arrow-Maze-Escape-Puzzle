/// Mensajes de derrota estandarizados para la capa de presentación.
class GameLossMessage {
  /// Crea un mensaje de derrota personalizado.
  const GameLossMessage(this.text);

  /// Se agotaron los movimientos permitidos ([Level.parMoves]).
  static const movesExceeded = GameLossMessage(
    'Has superado el número máximo de movimientos permitidos. ¡Has perdido!',
  );

  /// Se agotó el tiempo límite del nivel.
  static const timeExceeded = GameLossMessage(
    'Se agotó el tiempo límite del nivel. ¡Has perdido!',
  );

  /// Texto legible para mostrar al jugador.
  final String text;
}
