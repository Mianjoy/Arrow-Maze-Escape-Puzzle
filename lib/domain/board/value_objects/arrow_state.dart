/// Estado de una flecha durante el ciclo de vida de una partida.
enum ArrowState {
  /// Flecha presente en el tablero y susceptible de ser movida.
  active,

  /// Flecha bloqueada por otra flecha en su trayectoria.
  blocked,

  /// Flecha que salió exitosamente del tablero.
  extracted,
}
