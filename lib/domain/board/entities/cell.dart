import 'package:meta/meta.dart';

import '../../shared/value_objects/identifier.dart';
import '../../shared/value_objects/position.dart';
import 'arrow.dart';
import '../value_objects/cell_state.dart';

/// Entidad que representa una celda individual del tablero.
///
/// Mantiene su [position], [state] y opcionalmente la [arrowId] que la ocupa.
@immutable
class Cell {
  /// Crea una celda en [position] con [state] y referencia opcional a una flecha.
  const Cell({
    required this.position,
    this.state = CellState.empty,
    this.arrowId,
  });

  /// Coordenada de la celda en el grid.
  final Position position;

  /// Estado actual de la celda (vacía, ocupada o limpiada).
  final CellState state;

  /// Identificador de la flecha que ocupa la celda, si aplica.
  final Identifier? arrowId;

  /// Indica si la celda está disponible para colocar una flecha.
  bool get isEmpty => state == CellState.empty;

  /// Indica si la celda es un muro estático.
  bool get isWall => state == CellState.wall;

  /// Indica si la celda contiene una flecha activa.
  bool get isOccupied => state == CellState.occupied;

  /// Retorna una copia con los campos indicados reemplazados.
  Cell copyWith({
    Position? position,
    CellState? state,
    Identifier? arrowId,
    bool clearArrowId = false,
  }) {
    return Cell(
      position: position ?? this.position,
      state: state ?? this.state,
      arrowId: clearArrowId ? null : (arrowId ?? this.arrowId),
    );
  }

  /// Ocupa la celda con la flecha identificada por [arrow].
  Cell occupyWith(Arrow arrow) {
    return copyWith(
      state: CellState.occupied,
      arrowId: arrow.id,
    );
  }

  /// Libera la celda tras extraer la flecha.
  Cell clear() {
    return copyWith(
      state: CellState.cleared,
      clearArrowId: true,
    );
  }

  /// Marca la celda como muro estático (bloquea disparos, no es interactiva).
  ///
  /// Corresponde a una entrada del array `walls` del contrato wire.
  Cell asWall() {
    return copyWith(state: CellState.wall, clearArrowId: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          state == other.state &&
          arrowId == other.arrowId;

  @override
  int get hashCode => Object.hash(position, state, arrowId);

  @override
  String toString() => 'Cell(position: $position, state: $state, arrowId: $arrowId)';
}
