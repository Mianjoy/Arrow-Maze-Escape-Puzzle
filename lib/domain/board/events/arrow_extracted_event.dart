import '../../shared/value_objects/identifier.dart';
import '../../shared/value_objects/position.dart';

/// Evento de dominio emitido cuando una flecha es extraída del tablero.
class ArrowExtractedEvent {
  /// Crea el evento con el [arrowId] y la [position] de origen.
  const ArrowExtractedEvent({
    required this.arrowId,
    required this.position,
    required this.occurredAt,
  });

  /// Identificador de la flecha extraída.
  final Identifier arrowId;

  /// Posición que ocupaba la flecha antes de salir.
  final Position position;

  /// Marca temporal del evento (UTC).
  final DateTime occurredAt;
}
