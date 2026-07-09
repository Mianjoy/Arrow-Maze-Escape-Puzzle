/// Estado de progreso de un nivel individual para un jugador.
enum LevelProgressStatus {
  /// Nivel bloqueado, aún no disponible.
  locked,

  /// Nivel desbloqueado pero no completado.
  unlocked,

  /// Nivel completado al menos una vez.
  completed,
}
