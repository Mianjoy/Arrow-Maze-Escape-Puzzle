import 'package:meta/meta.dart';

import '../board/value_objects/face.dart';
import '../shared/exceptions/domain_exception.dart';

/// Posición en la superficie del cubo: cara + celda local (fila/columna).
@immutable
class CubeSurfacePosition {
  /// Crea una posición en [face] con [row] y [column] locales.
  const CubeSurfacePosition({
    required this.face,
    required this.row,
    required this.column,
  });

  /// Cara del cubo.
  final Face face;

  /// Fila local en la cara (0 .. faceSize-1).
  final int row;

  /// Columna local en la cara (0 .. faceSize-1).
  final int column;

  /// Valida que la posición esté dentro de una cara de tamaño [faceSize].
  void ensureWithin(int faceSize) {
    if (row < 0 || column < 0 || row >= faceSize || column >= faceSize) {
      throw DomainException(
        'CubeSurfacePosition($face, $row, $column) is outside ${faceSize}x$faceSize.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CubeSurfacePosition &&
          face == other.face &&
          row == other.row &&
          column == other.column;

  @override
  int get hashCode => Object.hash(face, row, column);

  @override
  String toString() => 'CubeSurfacePosition($face, $row, $column)';
}
