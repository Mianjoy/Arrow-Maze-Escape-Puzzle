import '../aggregates/board.dart';
import '../entities/arrow.dart';
import '../../shared/value_objects/position.dart';
import 'i_collision_validator.dart';

/// Implementación por defecto del validador de colisiones.
///
/// Recorre la trayectoria de la flecha celda a celda hasta encontrar
/// otra flecha activa o el borde del tablero.
class CollisionValidator implements ICollisionValidator {
  /// Crea una instancia del validador de colisiones.
  const CollisionValidator();

  @override
  Position? findBlockingPosition({
    required Board board,
    required Arrow arrow,
  }) {
    var current = arrow.position;

    while (true) {
      final next = arrow.direction.nextPositionFrom(current);

      if (!next.isWithinBounds(
        rows: board.dimension.rows,
        columns: board.dimension.columns,
      )) {
        return null;
      }

      final hasBlocker = board.activeArrows.any(
        (other) => other.position == next && other.id != arrow.id,
      );

      if (hasBlocker) {
        return next;
      }

      current = next;
    }
  }
}
