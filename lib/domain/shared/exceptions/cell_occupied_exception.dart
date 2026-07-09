import 'domain_exception.dart';

/// Excepción lanzada al intentar colocar una flecha en una celda ya ocupada.
class CellOccupiedException extends DomainException {
  /// Crea la excepción indicando la fila [row] y columna [column] conflictivas.
  CellOccupiedException({required int row, required int column})
      : super('Cell at ($row, $column) is already occupied.');
}
