import '../../domain/domain.dart';

/// Resultado de registrar una victoria: progreso actualizado y siguiente nivel.
class RecordVictoryResult {
  /// Crea el resultado con [progress] y el [nextLevel] desbloqueado (si hay).
  const RecordVictoryResult({
    required this.progress,
    this.nextLevel,
    this.syncError,
  });

  /// Progreso local tras completar el nivel.
  final PlayerProgress progress;

  /// Nivel siguiente en la secuencia, listo para jugar.
  final Level? nextLevel;

  /// Error de `POST /progress/sync`, o `null` si sincronizó correctamente.
  ///
  /// El progreso local y el desbloqueo del siguiente nivel ya se completaron
  /// aunque este campo no sea `null` — la sincronización remota es best-effort
  /// y no debe bloquear el avance del jugador cuando no hay red.
  final Object? syncError;
}
