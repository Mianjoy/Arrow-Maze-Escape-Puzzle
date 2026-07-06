import '../../level/value_objects/star_rating.dart';
import '../../shared/value_objects/identifier.dart';

/// Evento de dominio emitido cuando el jugador gana una partida.
class GameWonEvent {
  /// Crea el evento con referencias a la partida, jugador, nivel y estrellas.
  const GameWonEvent({
    required this.gameId,
    required this.playerId,
    required this.levelId,
    required this.moveCount,
    required this.starsEarned,
    required this.elapsedSeconds,
    required this.occurredAt,
  });

  /// Identificador de la partida ganada.
  final Identifier gameId;

  /// Jugador que ganó.
  final Identifier playerId;

  /// Nivel completado.
  final Identifier levelId;

  /// Movimientos totales realizados.
  final int moveCount;

  /// Estrellas obtenidas (1–3).
  final StarRating starsEarned;

  /// Duración de la partida en segundos.
  final int elapsedSeconds;

  /// Marca temporal del evento (UTC).
  final DateTime occurredAt;
}
