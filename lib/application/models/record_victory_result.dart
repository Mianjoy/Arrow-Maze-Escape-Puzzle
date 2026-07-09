import '../../domain/domain.dart';

/// Resultado de registrar una victoria: progreso actualizado y siguiente nivel.
class RecordVictoryResult {
  /// Crea el resultado con [progress] y el [nextLevel] desbloqueado (si hay).
  const RecordVictoryResult({
    required this.progress,
    this.nextLevel,
  });

  /// Progreso local tras completar el nivel.
  final PlayerProgress progress;

  /// Nivel siguiente en la secuencia, listo para jugar.
  final Level? nextLevel;
}
