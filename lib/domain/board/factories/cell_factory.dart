import '../../shared/value_objects/position.dart';
import '../entities/cell.dart';
import '../value_objects/cell_state.dart';

/// Factory (patrón Factory) para crear celdas del tablero.
class CellFactory {
  /// Crea una instancia de [CellFactory].
  const CellFactory();

  /// Genera una celda vacía en [position].
  Cell createEmpty(Position position) {
    return Cell(position: position, state: CellState.empty);
  }

  /// Genera la cuadrícula completa de celdas vacías para un tablero
  /// de [rows] filas y [columns] columnas.
  List<Cell> createGrid({required int rows, required int columns}) {
    final cells = <Cell>[];
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        cells.add(createEmpty(Position(row: row, column: column)));
      }
    }
    return cells;
  }
}
