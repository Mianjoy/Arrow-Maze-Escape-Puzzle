import 'package:meta/meta.dart';

/// Value object que define las dimensiones de un tablero rectangular.
@immutable
class BoardDimension {
  /// Crea dimensiones con [rows] filas y [columns] columnas, ambas mayores que cero.
  const BoardDimension({required this.rows, required this.columns})
      : assert(rows > 0, 'Rows must be positive'),
        assert(columns > 0, 'Columns must be positive');

  /// Número de filas del tablero.
  final int rows;

  /// Número de columnas del tablero.
  final int columns;

  /// Cantidad total de celdas (rows × columns).
  int get totalCells => rows * columns;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardDimension &&
          runtimeType == other.runtimeType &&
          rows == other.rows &&
          columns == other.columns;

  @override
  int get hashCode => Object.hash(rows, columns);

  @override
  String toString() => 'BoardDimension(rows: $rows, columns: $columns)';
}
