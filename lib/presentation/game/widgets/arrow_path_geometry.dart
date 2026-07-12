import 'dart:math' as math;
import 'dart:ui';

import '../../../domain/domain.dart';

/// Utilidades para convertir flechas multi-celda en trazos dibujables.
///
/// Simplifica segmentos colineales, redondea esquinas a 90° y alinea la cabeza
/// con el cuerpo para evitar codos y costuras visibles.
abstract final class ArrowPathGeometry {
  /// Devuelve las posiciones ordenadas de la cola a la cabeza para dibujar el trazo.
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
        orderedHeadToTail.addAll(remaining);
        break;
      }
      orderedHeadToTail.add(next);
      remaining.remove(next);
      current = next;
    }

    return orderedHeadToTail.reversed.toList();
  }

  /// Elimina vértices intermedios en líneas rectas (colineales).
  static List<Position> simplifyCollinear(List<Position> positions) {
    if (positions.length <= 2) {
      return List<Position>.from(positions);
    }

    final simplified = <Position>[positions.first];
    for (var i = 1; i < positions.length - 1; i++) {
      if (!_isCollinear(positions[i - 1], positions[i], positions[i + 1])) {
        simplified.add(positions[i]);
      }
    }
    simplified.add(positions.last);
    return simplified;
  }

  /// Construye el trazo del cuerpo hasta [headBase], con esquinas redondeadas.
  static Path buildBodyPath({
    required List<Position> positions,
    required Position head,
    required double cellWidth,
    required double cellHeight,
    required Offset headBase,
    required double cornerRadius,
  }) {
    final simplified = simplifyCollinear(positions);
    if (simplified.isEmpty) {
      return Path();
    }

    final points = simplified
        .map(
          (position) => cellCenter(
            position,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
          ),
        )
        .toList();

    final headCenter = cellCenter(
      head,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    if (points.length == 1) {
      _lineAxisAligned(path, points.first, headCenter);
      _lineAxisAligned(path, headCenter, headBase);
      return path;
    }

    if (points.length == 2) {
      _lineAxisAligned(path, points[0], points[1]);
    } else {
      for (var i = 1; i < points.length - 1; i++) {
        _addRoundedCorner(
          path,
          points[i - 1],
          points[i],
          points[i + 1],
          cornerRadius,
        );
      }
      path.lineTo(points.last.dx, points.last.dy);
    }

    _lineAxisAligned(path, points.last, headCenter);
    _lineAxisAligned(path, headCenter, headBase);
    return path;
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

  /// Punta de la flecha en el borde de la celda de cabeza, con [margin] de inset.
  static Offset headTip({
    required Position head,
    required Direction direction,
    required double cellWidth,
    required double cellHeight,
    required double margin,
  }) {
    final left = head.column * cellWidth;
    final top = head.row * cellHeight;
    final centerX = left + cellWidth / 2;
    final centerY = top + cellHeight / 2;

    return switch (direction.arrowDirection) {
      ArrowDirection.up => Offset(centerX, top + margin),
      ArrowDirection.down => Offset(centerX, top + cellHeight - margin),
      ArrowDirection.left => Offset(left + margin, centerY),
      ArrowDirection.right => Offset(left + cellWidth - margin, centerY),
    };
  }

  /// Base del triángulo de cabeza, donde debe terminar el trazo del cuerpo.
  static Offset headBase({
    required Offset tip,
    required Direction direction,
    required double headLength,
  }) {
    final angle = _angleFor(direction);
    return tip - Offset(math.cos(angle), math.sin(angle)) * headLength;
  }

  static void _lineAxisAligned(Path path, Offset from, Offset to) {
    if ((from.dx - to.dx).abs() < 0.001) {
      path.lineTo(from.dx, to.dy);
      return;
    }
    if ((from.dy - to.dy).abs() < 0.001) {
      path.lineTo(to.dx, from.dy);
      return;
    }
    path.lineTo(to.dx, to.dy);
  }

  static void _addRoundedCorner(
    Path path,
    Offset previous,
    Offset corner,
    Offset next,
    double radius,
  ) {
    final inVector = corner - previous;
    final outVector = next - corner;
    final inLength = inVector.distance;
    final outLength = outVector.distance;
    if (inLength < 0.001 || outLength < 0.001) {
      path.lineTo(corner.dx, corner.dy);
      return;
    }

    final effectiveRadius = math.min(radius, math.min(inLength, outLength) / 2);
    final inUnit = inVector / inLength;
    final outUnit = outVector / outLength;
    final beforeCorner = corner - inUnit * effectiveRadius;
    final afterCorner = corner + outUnit * effectiveRadius;

    path.lineTo(beforeCorner.dx, beforeCorner.dy);
    path.quadraticBezierTo(corner.dx, corner.dy, afterCorner.dx, afterCorner.dy);
  }

  static bool _isCollinear(Position a, Position b, Position c) {
    final dr1 = b.row - a.row;
    final dc1 = b.column - a.column;
    final dr2 = c.row - b.row;
    final dc2 = c.column - b.column;
    return dr1 * dc2 == dr2 * dc1;
  }

  static double _angleFor(Direction direction) {
    return switch (direction.arrowDirection) {
      ArrowDirection.right => 0,
      ArrowDirection.down => math.pi / 2,
      ArrowDirection.left => math.pi,
      ArrowDirection.up => -math.pi / 2,
    };
  }

  static Position? _pickAdjacent(
    Position current,
    Set<Position> candidates,
    Direction direction,
  ) {
    final opposite = direction.opposite;
    final preferredRow = current.row + opposite.deltaRow;
    final preferredCol = current.column + opposite.deltaColumn;
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

  static bool _isAdjacent(Position a, Position b) {
    final dRow = (a.row - b.row).abs();
    final dCol = (a.column - b.column).abs();
    return dRow + dCol == 1;
  }
}
