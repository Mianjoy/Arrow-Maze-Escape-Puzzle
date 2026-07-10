/// Progreso de un nivel tal como lo devuelve el backend en `GET /progress`.
///
/// Espejo del `ProgressResultDto` del servidor; el cliente lo fusiona con su
/// progreso local vía `PlayerProgress.mergeRemoteLevel`.
class RemoteLevelProgress {
  /// Crea la entrada con los campos del contrato del backend.
  const RemoteLevelProgress({
    required this.levelId,
    required this.highScore,
    required this.minMoves,
    required this.minTimeInSeconds,
    required this.isCompleted,
  });

  /// Identificador del nivel.
  final String levelId;

  /// Mejor puntaje registrado en el servidor.
  final int highScore;

  /// Menor cantidad de movimientos registrada.
  final int minMoves;

  /// Menor tiempo registrado (segundos).
  final int minTimeInSeconds;

  /// Si el nivel figura como completado en el servidor.
  final bool isCompleted;

  /// Reconstruye una entrada desde el JSON del backend.
  factory RemoteLevelProgress.fromJson(Map<String, dynamic> json) {
    return RemoteLevelProgress(
      levelId: json['levelId'] as String,
      highScore: (json['highScore'] as num).toInt(),
      minMoves: (json['minMoves'] as num).toInt(),
      minTimeInSeconds: (json['minTimeInSeconds'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
    );
  }
}
