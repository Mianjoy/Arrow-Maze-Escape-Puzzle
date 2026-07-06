import 'domain_exception.dart';

/// Excepción lanzada cuando un movimiento de flecha no cumple las reglas del juego.
///
/// Ejemplos: flecha bloqueada, ya extraída, o partida finalizada.
class InvalidMoveException extends DomainException {
  /// Crea la excepción con un [message] que detalla el motivo del rechazo.
  const InvalidMoveException(super.message);
}
