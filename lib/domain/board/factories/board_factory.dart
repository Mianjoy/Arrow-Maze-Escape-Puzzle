import '../../shared/value_objects/identifier.dart';
import '../entities/board.dart';
import '../value_objects/board_dimension.dart';
import 'cell_factory.dart';

/// Factory (patrón Factory) para instanciar tableros vacíos o preconfigurados.
class BoardFactory {
  /// Crea una factory con una [CellFactory] inyectable.
  const BoardFactory({CellFactory? cellFactory})
      : _cellFactory = cellFactory ?? const CellFactory();

  final CellFactory _cellFactory;

  /// Crea un tablero vacío con [id] y [dimension].
  Board createEmpty({
    required Identifier id,
    required BoardDimension dimension,
  }) {
    final cells = _cellFactory.createGrid(
      rows: dimension.rows,
      columns: dimension.columns,
    );

    return Board(
      id: id,
      dimension: dimension,
      cells: cells,
      arrows: const [],
    );
  }
}
