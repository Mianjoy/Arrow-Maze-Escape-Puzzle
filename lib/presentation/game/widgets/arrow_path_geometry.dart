import 'dart:ui';

import '../../../domain/domain.dart';

/// Utilidades para convertir flechas multi-celda en polilíneas dibujables.
///
/// Ordena cabeza y segmentos de cuerpo de cola a punta para que el
/// [ArrowBoardPainter] trace un único trazo continuo con punta en la cabeza.
abstract final class ArrowPathGeometry {
  /// Devuelve las posiciones ordenadas de la cola a la cabeza para dibujar el trazo.
  ///
  /// Recorre desde [Arrow.position] hacia los segmentos de [Arrow.body]
  /// siguiendo adyacencia en el grid (soporta líneas rectas y esquinas en L).
  static List<Position> tailToHead(Arrow arrow) {
    if (arrow.body.isEmpty) {
      return [arrow.position];
    }

    final orderedHeadToTail = <Position>[arrow.position];
    final remaining = {...arrow.body};

    var current = arrow.position;
    while (remaining.isNotEmpty) {
      final next = _pickAdjacent(current, remaining, arrow.direction);
      if (next == null) {
        // Fallback: añade el resto en orden arbitrario si el JSON es degenerado.
        orderedHeadToTail.addAll(remaining);
        break;
      }
      orderedHeadToTail.add(next);
      remaining.remove(next);
      current = next;
    }

    return orderedHeadToTail.reversed.toList();
  }

  /// Convierte una [Position] de grid al centro de su celda en coordenadas de lienzo.
  static Offset cellCenter(
    Position position, {
    required double cellWidth,
    required double cellHeight,
  }) {
    return Offset(
      (position.column + 0.5) * cellWidth,
      (position.row + 0.5) * cellHeight,
    );
  }

  /// Elige la celda adyacente siguiente al encadenar el cuerpo de la flecha.
  ///
  /// Prioriza la celda alineada con la dirección opuesta al disparo (cola recta).
  static Position? _pickAdjacent(
    Position current,
    Set<Position> candidates,
    Direction direction,
  ) {
    final opposite = direction.opposite;
    final preferredRow = current.row + opposite.deltaRow;
    final preferredCol = current.column + opposite.deltaColumn;
    // `Position` exige coordenadas no negativas; cerca del borde del tablero
    // esta "adivinanza" de la celda en línea recta puede caer fuera de la
    // rejilla (fila/columna negativa), así que se valida antes de construirla
    // en vez de dejar que el assert del constructor aborte el pintado.
    if (preferredRow >= 0 && preferredCol >= 0) {
      final preferred = Position(row: preferredRow, column: preferredCol);
      if (candidates.contains(preferred)) {
        return preferred;
      }
    }

    for (final candidate in candidates) {
      if (_isAdjacent(current, candidate)) {
        return candidate;
      }
    }
    return null;
  }

  /// Indica si dos posiciones comparten lado en el grid (distancia Manhattan 1).
  static bool _isAdjacent(Position a, Position b) {
    final dRow = (a.row - b.row).abs();
    final dCol = (a.column - b.column).abs();
    return dRow + dCol == 1;
  }
}
