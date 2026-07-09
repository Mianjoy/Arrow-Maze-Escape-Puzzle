import 'package:meta/meta.dart';

import '../../shared/value_objects/position.dart';

/// Value object con la posición inicial del jugador en un nivel.
///
/// Proviene del campo `playerStart` del JSON del nivel.
@immutable
class PlayerStart {
  /// Crea la posición inicial del jugador.
  const PlayerStart({required this.position});

  /// Coordenada de inicio en el tablero.
  final Position position;

  /// Parsea `playerStart` desde un mapa JSON.
  ///
  /// Acepta claves `row`/`col` o `row`/`column`.
  factory PlayerStart.fromJson(Map<String, dynamic> json) {
    return PlayerStart(
      position: Position(
        row: _requireInt(json, 'row'),
        column: _requireInt(json, 'col', fallbackKey: 'column'),
      ),
    );
  }

  /// Serializa a un mapa compatible con el esquema JSON del nivel.
  Map<String, dynamic> toJson() => {
        'row': position.row,
        'col': position.column,
      };

  static int _requireInt(
    Map<String, dynamic> json,
    String key, {
    String? fallbackKey,
  }) {
    final value = json[key] ?? (fallbackKey != null ? json[fallbackKey] : null);
    if (value is! int) {
      throw FormatException('Expected int for "$key" in playerStart.');
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStart &&
          runtimeType == other.runtimeType &&
          position == other.position;

  @override
  int get hashCode => position.hashCode;
}
