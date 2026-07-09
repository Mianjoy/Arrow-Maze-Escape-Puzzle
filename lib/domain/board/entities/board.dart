import 'package:meta/meta.dart';

import '../../shared/value_objects/identifier.dart';
import '../../shared/value_objects/position.dart';
import '../value_objects/board_dimension.dart';
import 'arrow.dart';
import 'cell.dart';
import '../../shared/exceptions/cell_occupied_exception.dart';
import '../../shared/exceptions/domain_exception.dart';

/// Entidad que representa el estado del tablero en un momento dado.
///
/// Contiene [Cell] y [Arrow] sin orquestar reglas de juego.
/// Las mutaciones durante una partida las coordina el agregado [Game];
/// la definición inicial proviene del agregado [Level].
@immutable
class Board {
  /// Crea un tablero con [id], [dimension] y colecciones iniciales.
  ///
  /// [domainEvents] son los eventos de dominio pendientes de consumir
  /// (ver [pullDomainEvents]); por defecto no hay ninguno pendiente.
  Board({
    required this.id,
    required this.dimension,
    required List<Cell> cells,
    required List<Arrow> arrows,
    List<Object> domainEvents = const [],
  })  : _cells = List.unmodifiable(cells),
        _arrows = List.unmodifiable(arrows),
        _domainEvents = List.unmodifiable(domainEvents) {
    _validateInvariants();
  }

  /// Identificador único del tablero.
  final Identifier id;

  /// Dimensiones del grid.
  final BoardDimension dimension;

  final List<Cell> _cells;
  final List<Arrow> _arrows;
  final List<Object> _domainEvents;

  /// Vista de solo lectura de todas las celdas.
  List<Cell> get cells => _cells;

  /// Vista de solo lectura de todas las flechas.
  List<Arrow> get arrows => _arrows;

  /// Eventos de dominio pendientes de consumir (p. ej. ArrowBlockedEvent,
  /// ArrowExtractedEvent, emitidos por ArrowMovementEngine).
  ///
  /// Portado desde el dominio en español (`Tablero.consumirEventosDominio()`
  /// en la rama `Integracion`). Como [Board] es inmutable, "consumir" se
  /// modela en dos pasos: leer [domainEvents] y luego pedir una copia sin
  /// ellos con [pullDomainEvents].
  List<Object> get domainEvents => _domainEvents;

  /// Retorna una copia de este tablero con [event] agregado a los eventos
  /// de dominio pendientes.
  Board withDomainEvent(Object event) {
    return Board(
      id: id,
      dimension: dimension,
      cells: _cells,
      arrows: _arrows,
      domainEvents: [..._domainEvents, event],
    );
  }

  /// Retorna (eventos pendientes, tablero con los eventos ya vaciados).
  ///
  /// Equivalente inmutable de "drenar" la cola de eventos: quien llama
  /// obtiene la lista actual y debe quedarse con el tablero devuelto para
  /// no procesar los mismos eventos dos veces.
  ({List<Object> events, Board board}) pullDomainEvents() {
    final events = _domainEvents;
    final cleared = Board(
      id: id,
      dimension: dimension,
      cells: _cells,
      arrows: _arrows,
    );
    return (events: events, board: cleared);
  }

  /// Flechas que aún permanecen en el tablero (todas las que no han sido
  /// extraídas).
  ///
  /// Incluye tanto las `active` como las `blocked`: una flecha bloqueada
  /// sigue ocupando físicamente su celda, así que sigue bloqueando a otras
  /// (ver [CollisionValidator]) y el nivel NO está resuelto mientras quede
  /// alguna. Solo una flecha `extracted` deja de contar. (Antes este getter
  /// filtraba por `state == active`, lo que hacía que una flecha bloqueada
  /// "desapareciera" del tablero: dejaba de bloquear y el nivel se declaraba
  /// resuelto con flechas aún presentes.)
  List<Arrow> get activeArrows =>
      _arrows.where((arrow) => !arrow.isExtracted).toList();

  /// Indica si todas las flechas han sido extraídas.
  bool get isCleared => activeArrows.isEmpty;

  /// Obtiene la celda en [position] o lanza [DomainException] si no existe.
  Cell cellAt(Position position) {
    return _cells.firstWhere(
      (cell) => cell.position == position,
      orElse: () => throw DomainException('No cell at position $position.'),
    );
  }

  /// Devuelve el [Identifier] de la flecha en [position], o `null` si la
  /// celda está vacía.
  ///
  /// Agregado durante la fusión de dominio de Sprint 1 para soportar el
  /// caso "sin flecha" portado desde la rama `Integracion` (ver
  /// [ArrowMovementEngine.attemptMoveAt]).
  Identifier? arrowIdAt(Position position) {
    return cellAt(position).arrowId;
  }

  /// Obtiene la flecha con [arrowId] o lanza [DomainException] si no existe.
  Arrow arrowById(Identifier arrowId) {
    return _arrows.firstWhere(
      (arrow) => arrow.id == arrowId,
      orElse: () => throw DomainException('Arrow $arrowId not found on board.'),
    );
  }

  /// Coloca una [arrow] en el tablero si la celda destino está vacía.
  ///
  /// Usado al construir el tablero desde la definición del nivel.
  /// Lanza [CellOccupiedException] si la posición ya está ocupada.
  Board placeArrow(Arrow arrow) {
    final targetCell = cellAt(arrow.position);
    if (!targetCell.isEmpty) {
      throw CellOccupiedException(
        row: arrow.position.row,
        column: arrow.position.column,
      );
    }

    arrow.position.ensureWithinBounds(
      rows: dimension.rows,
      columns: dimension.columns,
    );

    final updatedCells = _cells
        .map((cell) => cell.position == arrow.position ? cell.occupyWith(arrow) : cell)
        .toList();

    return Board(
      id: id,
      dimension: dimension,
      cells: updatedCells,
      arrows: [..._arrows, arrow],
      domainEvents: _domainEvents,
    );
  }

  /// Actualiza el estado de una flecha y su celda asociada.
  Board applyArrowUpdate(Arrow updatedArrow, {bool clearCell = false}) {
    final updatedArrows = _arrows
        .map((arrow) => arrow.id == updatedArrow.id ? updatedArrow : arrow)
        .toList();

    final updatedCells = _cells.map((cell) {
      if (cell.arrowId == updatedArrow.id && clearCell) {
        return cell.clear();
      }
      return cell;
    }).toList();

    return Board(
      id: id,
      dimension: dimension,
      cells: updatedCells,
      arrows: updatedArrows,
      domainEvents: _domainEvents,
    );
  }

  void _validateInvariants() {
    final occupiedPositions = <Position>{};
    for (final arrow in _arrows.where((a) => !a.isExtracted)) {
      if (!occupiedPositions.add(arrow.position)) {
        throw DomainException(
          'Invariant violation: multiple arrows at position ${arrow.position}.',
        );
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Board &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dimension == other.dimension;

  @override
  int get hashCode => Object.hash(id, dimension);

  @override
  String toString() => 'Board(id: $id, dimension: $dimension, arrows: ${_arrows.length})';
}
