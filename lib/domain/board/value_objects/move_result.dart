import 'package:meta/meta.dart';

import '../../shared/value_objects/identifier.dart';
import '../../shared/value_objects/position.dart';

/// Resultado de intentar mover una flecha en el tablero.
@immutable
class MoveResult {
  /// Crea un resultado de movimiento con su [type] y metadatos opcionales.
  const MoveResult({
    required this.type,
    this.arrowId,
    this.blockingPosition,
    this.message,
  });

  /// Tipo de resultado del movimiento.
  final MoveResultType type;

  /// Identificador de la flecha involucrada.
  final Identifier? arrowId;

  /// Posición donde se bloqueó el movimiento, si aplica.
  final Position? blockingPosition;

  /// Mensaje descriptivo adicional.
  final String? message;

  /// Indica si la flecha salió exitosamente del tablero.
  bool get isExtracted => type == MoveResultType.extracted;

  /// Indica si el movimiento fue bloqueado por otra flecha.
  bool get isBlocked => type == MoveResultType.blocked;

  /// Factory para un movimiento exitoso de extracción.
  factory MoveResult.extracted({required Identifier arrowId}) {
    return MoveResult(type: MoveResultType.extracted, arrowId: arrowId);
  }

  /// Factory para un movimiento bloqueado.
  factory MoveResult.blocked({
    required Identifier arrowId,
    required Position blockingPosition,
  }) {
    return MoveResult(
      type: MoveResultType.blocked,
      arrowId: arrowId,
      blockingPosition: blockingPosition,
    );
  }

  /// Factory para un movimiento inválido.
  factory MoveResult.invalid({required String message}) {
    return MoveResult(type: MoveResultType.invalid, message: message);
  }
}

/// Clasificación del resultado de un intento de movimiento.
enum MoveResultType {
  /// La flecha salió del tablero.
  extracted,

  /// Otra flecha bloqueó el camino.
  blocked,

  /// El movimiento no es válido (regla de negocio).
  invalid,
}
