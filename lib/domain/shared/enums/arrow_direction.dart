/// Direcciones cardinales en las que puede apuntar una flecha del tablero.
///
/// Cada valor representa el sentido de desplazamiento cuando el jugador
/// intenta extraer una flecha del [Board].
enum ArrowDirection {
  /// Flecha apunta hacia arriba (decrementa la fila).
  up,

  /// Flecha apunta hacia abajo (incrementa la fila).
  down,

  /// Flecha apunta hacia la izquierda (decrementa la columna).
  left,

  /// Flecha apunta hacia la derecha (incrementa la columna).
  right,
}
