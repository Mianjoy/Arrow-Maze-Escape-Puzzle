/// Estado operativo de una celda dentro del [Board].
enum CellState {
  /// Celda vacía, disponible para recibir una flecha.
  empty,

  /// Celda ocupada por una flecha activa en el tablero.
  occupied,

  /// Celda que alguna vez tuvo una flecha ya extraída (opcional para trazabilidad).
  cleared,

  /// Muro estático que bloquea la trayectoria de las flechas.
  wall,
}
