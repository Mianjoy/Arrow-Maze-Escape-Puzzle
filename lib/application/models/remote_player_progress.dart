/// Progreso remoto descargado del servidor (niveles + coleccionables).
class RemotePlayerProgress {
  /// Crea el snapshot remoto.
  const RemotePlayerProgress({
    required this.levels,
    required this.collectibles,
  });

  /// Progreso por nivel almacenado en el backend.
  final List<RemoteLevelProgress> levels;

  /// Identificadores de coleccionables desbloqueados en el servidor.
  final List<String> collectibles;
}

/// Progreso remoto de un nivel concreto.
class RemoteLevelProgress {
  /// Crea la entrada remota desde JSON del backend.
  const RemoteLevelProgress({
    required this.levelId,
    required this.highScore,
    required this.minMoves,
    required this.minTimeInSeconds,
    required this.isCompleted,
  });

  /// Identificador del nivel.
  final String levelId;

  /// Mejor puntuación registrada.
  final int highScore;

  /// Menor cantidad de movimientos.
  final int minMoves;

  /// Menor tiempo en segundos.
  final int minTimeInSeconds;

  /// Si el nivel fue completado al menos una vez.
  final bool isCompleted;

  /// Parsea la respuesta de `GET /progress`.
  factory RemoteLevelProgress.fromJson(Map<String, dynamic> json) {
    return RemoteLevelProgress(
      levelId: json['levelId'] as String,
      highScore: json['highScore'] as int,
      minMoves: json['minMoves'] as int,
      minTimeInSeconds: json['minTimeInSeconds'] as int,
      isCompleted: json['isCompleted'] as bool,
    );
  }
}
