import 'package:meta/meta.dart';

import '../../shared/enums/arrow_direction.dart';
import '../../shared/value_objects/direction.dart';
import '../../shared/value_objects/position.dart';

/// Value object con la definición estática de una celda del nivel (JSON).
///
/// Representa un elemento del array `board.cells` del archivo de nivel.
@immutable
class LevelCellData {
  /// Crea la definición de celda con [position] y [direction] opcional.
  const LevelCellData({
    required this.position,
    this.direction,
  });

  /// Coordenada de la celda en el grid.
  final Position position;

  /// Dirección de la flecha si la celda contiene una; `null` si está vacía.
  final Direction? direction;

  /// Indica si la celda define una flecha.
  bool get hasArrow => direction != null;

  /// Parsea una celda desde un elemento del array `board.cells`.
  ///
  /// Acepta `col` o `column`, y `direction` como string (`up`, `down`, etc.).
  factory LevelCellData.fromJson(Map<String, dynamic> json) {
    final directionRaw = json['direction'] as String?;
    return LevelCellData(
      position: Position(
        row: _requireInt(json, 'row'),
        column: _requireInt(json, 'col', fallbackKey: 'column'),
      ),
      direction: directionRaw != null
          ? Direction(_parseDirection(directionRaw))
          : null,
    );
  }

  /// Serializa la celda al formato JSON del nivel.
  Map<String, dynamic> toJson() => {
        'row': position.row,
        'col': position.column,
        if (direction != null) 'direction': direction!.arrowDirection.name,
      };

  static ArrowDirection _parseDirection(String raw) {
    return ArrowDirection.values.firstWhere(
      (d) => d.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => throw FormatException('Unknown arrow direction: $raw'),
    );
  }

  static int _requireInt(
    Map<String, dynamic> json,
    String key, {
    String? fallbackKey,
  }) {
    final value = json[key] ?? (fallbackKey != null ? json[fallbackKey] : null);
    if (value is! int) {
      throw FormatException('Expected int for "$key" in board.cells item.');
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelCellData &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(position, direction);
}
