import '../../shared/value_objects/identifier.dart';
import '../../shared/value_objects/position.dart';

/// Evento de dominio emitido cuando una flecha queda bloqueada.
class ArrowBlockedEvent {
  /// Crea el evento con referencias a la flecha y el punto de bloqueo.
  const ArrowBlockedEvent({
    required this.arrowId,
    required this.blockingPosition,
    required this.occurredAt,
  });

  /// Identificador de la flecha bloqueada.
  final Identifier arrowId;

  /// Posición donde se encontró el obstáculo.
  final Position blockingPosition;

  /// Marca temporal del evento (UTC).
  final DateTime occurredAt;
}
