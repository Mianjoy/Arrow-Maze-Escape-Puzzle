import 'package:meta/meta.dart';

import '../../board/value_objects/board_dimension.dart';
import '../../shared/value_objects/position.dart';
import 'level_arrow_placement.dart';
import 'level_cell_data.dart';

/// Value object con la definición estática del tablero de un nivel (JSON).
///
/// Soporta el formato legacy (`board.cells`) y el wire format compartido
/// (`arrowPlacements`, `walls`, `exit`) vía [LevelDtoMapper].
@immutable
class LevelBoardDefinition {
  /// Crea la definición con [dimension] y datos de layout.
  const LevelBoardDefinition({
    required this.dimension,
    this.cells = const [],
    this.arrowPlacements = const [],
    this.walls = const [],
    this.exit,
  });

  /// Dimensiones del tablero (`rows` × `cols`).
  final BoardDimension dimension;

  /// Definición legacy: celdas con flecha de una sola celda (`board.cells` en JSON local).
  final List<LevelCellData> cells;

  /// Definición wire format: flechas con `head` y `body` del contrato compartido.
  final List<LevelArrowPlacement> arrowPlacements;

  /// Posiciones de muros estáticos (`walls` en el contrato; bloquean disparos).
  final List<Position> walls;

  /// Celda de salida (`exit` en el contrato); referencia visual en la UI.
  final Position? exit;

  /// `true` si el nivel se cargó vía [LevelDtoMapper] (tiene `arrowPlacements`).
  bool get usesWireLayout => arrowPlacements.isNotEmpty;

  /// Celdas que contienen flecha (formato legacy).
  List<LevelCellData> get arrowCells => cells.where((c) => c.hasArrow).toList();

  /// Parsea el objeto `board` desde el JSON del nivel.
  factory LevelBoardDefinition.fromJson(Map<String, dynamic> json) {
    final rows = _requireInt(json, 'rows');
    final cols = _requireInt(json, 'cols', fallbackKey: 'columns');

    final cellsJson = json['cells'];
    if (cellsJson is! List) {
      throw const FormatException('Expected array for board.cells.');
    }

    final cells = cellsJson
        .map((item) => LevelCellData.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return LevelBoardDefinition(
      dimension: BoardDimension(rows: rows, columns: cols),
      cells: cells,
    );
  }

  /// Serializa al formato JSON del nivel.
  Map<String, dynamic> toJson() => {
        'rows': dimension.rows,
        'cols': dimension.columns,
        'cells': cells.map((c) => c.toJson()).toList(),
      };

  static int _requireInt(
    Map<String, dynamic> json,
    String key, {
    String? fallbackKey,
  }) {
    final value = json[key] ?? (fallbackKey != null ? json[fallbackKey] : null);
    if (value is! int) {
      throw FormatException('Expected int for "$key" in board.');
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelBoardDefinition &&
          runtimeType == other.runtimeType &&
          dimension == other.dimension &&
          _listEquals(cells, other.cells);

  @override
  int get hashCode => Object.hash(dimension, Object.hashAll(cells));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
