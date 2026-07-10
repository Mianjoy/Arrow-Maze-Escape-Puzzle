import '../../domain/domain.dart';

/// Sincronización de progreso que no pudo enviarse al backend en el momento
/// de ganar un nivel (sin red, backend caído, etc.) y queda pendiente de
/// reintento.
class PendingSyncEntry {
  /// Crea la entrada pendiente con los datos ya calculados de la victoria.
  const PendingSyncEntry({
    required this.playerId,
    required this.levelId,
    required this.score,
    required this.moves,
    required this.timeInSeconds,
  });

  /// Jugador dueño de esta sincronización pendiente.
  final Identifier playerId;

  /// Nivel completado que generó esta entrada.
  final Identifier levelId;

  /// Puntaje obtenido en el intento.
  final int score;

  /// Movimientos usados en el intento.
  final int moves;

  /// Tiempo transcurrido en segundos.
  final int timeInSeconds;

  /// Serializa a un mapa JSON-compatible para persistencia.
  Map<String, dynamic> toJson() => {
        'playerId': playerId.value,
        'levelId': levelId.value,
        'score': score,
        'moves': moves,
        'timeInSeconds': timeInSeconds,
      };

  /// Reconstruye una entrada desde un mapa previamente serializado.
  factory PendingSyncEntry.fromJson(Map<String, dynamic> json) {
    return PendingSyncEntry(
      playerId: Identifier(json['playerId'] as String),
      levelId: Identifier(json['levelId'] as String),
      score: json['score'] as int,
      moves: json['moves'] as int,
      timeInSeconds: json['timeInSeconds'] as int,
    );
  }
}
