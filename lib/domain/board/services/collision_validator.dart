import '../entities/board.dart';
import '../entities/arrow.dart';
import '../../shared/value_objects/position.dart';
import 'i_collision_validator.dart';

/// Implementación por defecto del validador de colisiones.
///
/// Recorre la trayectoria de la flecha celda a celda desde su cabeza hasta:
/// - el borde del tablero (trayectoria libre → la flecha puede extraerse), o
/// - otra flecha no extraída que ocupe la celda (bloqueo), o
/// - un muro ([CellState.wall]) del wire format.
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

      // Salir del tablero = trayectoria despejada (extracción permitida).
      if (!next.isWithinBounds(
        rows: board.dimension.rows,
        columns: board.dimension.columns,
      )) {
        return null;
      }

      final cell = board.cellAt(next);
      // Muro del contrato wire: bloquea igual que otra flecha.
      if (cell.isWall) {
        return next;
      }

      // Otra flecha (cabeza o cuerpo) en la trayectoria bloquea el disparo.
      final hasBlocker = board.activeArrows.any(
        (other) => other.id != arrow.id && other.occupies(next),
      );

      if (hasBlocker) {
        return next;
      }

      current = next;
    }
  }
}
