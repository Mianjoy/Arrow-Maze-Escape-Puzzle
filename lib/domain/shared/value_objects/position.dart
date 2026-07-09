import 'package:meta/meta.dart';

import '../exceptions/domain_exception.dart';

/// Value object que representa una coordenada bidimensional en el tablero.
///
/// Las coordenadas son cero-indexadas: (0, 0) es la esquina superior izquierda.
@immutable
class Position {
  /// Crea una posición con [row] (fila) y [column] (columna) no negativas.
  const Position({required this.row, required this.column})
      : assert(row >= 0, 'Row must be non-negative'),
        assert(column >= 0, 'Column must be non-negative');

  /// Índice de fila (eje vertical).
  final int row;

  /// Índice de columna (eje horizontal).
  final int column;

  /// Desplaza la posición según el delta de fila [dRow] y columna [dCol].
  Position translate({required int dRow, required int dCol}) {
    return Position(row: row + dRow, column: column + dCol);
  }

  /// Indica si esta posición se encuentra dentro de un tablero de
  /// [rows] filas y [columns] columnas.
  bool isWithinBounds({required int rows, required int columns}) {
    return row >= 0 && row < rows && column >= 0 && column < columns;
  }

  /// Valida que la posición esté dentro del tablero; lanza [DomainException] si no.
  void ensureWithinBounds({required int rows, required int columns}) {
    if (!isWithinBounds(rows: rows, columns: columns)) {
      throw DomainException(
        'Position ($row, $column) is out of bounds for a $rows x $columns board.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          column == other.column;

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => 'Position(row: $row, column: $column)';
}
