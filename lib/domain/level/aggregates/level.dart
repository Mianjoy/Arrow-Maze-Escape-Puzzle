import 'package:meta/meta.dart';

import '../../board/entities/board.dart';
import '../../board/entities/arrow.dart';
import '../../board/factories/board_factory.dart';
import '../../shared/value_objects/identifier.dart';
import '../value_objects/level_board_definition.dart';
import '../value_objects/level_difficulty.dart';
import '../value_objects/player_start.dart';
import '../services/shortest_path_calculator.dart';

/// Agregado raíz que define un nivel jugable cargado desde JSON.
///
/// Contiene la definición estática del tablero, límites de juego
/// (`parMoves`, `timeLimit`) y la ruta óptima calculada (`optimalMoves`).
/// No muta estado de partida; eso lo coordina [Game].
@immutable
class Level {
  /// Crea un nivel con todos sus datos de definición.
  const Level({
    required this.id,
    required this.difficulty,
    required this.boardDefinition,
    required this.playerStart,
    required this.parMoves,
    required this.optimalMoves,
    this.levelNumber,
    this.timeLimit,
  })  : assert(parMoves > 0, 'parMoves must be positive'),
        assert(optimalMoves > 0, 'optimalMoves must be positive'),
        assert(
          optimalMoves <= parMoves,
          'optimalMoves cannot exceed parMoves',
        );

  /// Identificador único del nivel (string del JSON).
  final Identifier id;

  /// Número ordinal en la progresión (wire format `levelNumber`).
  final int? levelNumber;

  /// Dificultad del nivel.
  final LevelDifficulty difficulty;

  /// Definición estática del tablero (`board` en JSON).
  final LevelBoardDefinition boardDefinition;

  /// Posición inicial del jugador (`playerStart` en JSON).
  final PlayerStart playerStart;

  /// Máximo de movimientos permitidos antes de perder (`parMoves` en JSON).
  final int parMoves;

  /// Movimientos de la ruta más corta, calculados al cargar el nivel.
  final int optimalMoves;

  /// Límite de tiempo opcional en segundos (`timeLimit` en JSON).
  final int? timeLimit;

  /// Construye el [Board] inicial listo para iniciar una partida.
  ///
  /// Orden de aplicación (wire format):
  /// 1. Tablero vacío → 2. muros → 3. flechas multi-celda.
  /// Formato legacy: solo flechas de una celda vía [LevelBoardDefinition.cells].
  Board buildInitialBoard({BoardFactory? boardFactory}) {
    final factory = boardFactory ?? const BoardFactory();
    var board = factory.createEmpty(
      id: Identifier('board-${id.value}'),
      dimension: boardDefinition.dimension,
    );

    for (final wall in boardDefinition.walls) {
      board = board.markWall(wall);
    }

    if (boardDefinition.usesWireLayout) {
      for (final placement in boardDefinition.arrowPlacements) {
        final arrow = Arrow(
          id: placement.id,
          position: placement.head,
          direction: placement.direction,
          body: placement.body,
        );
        board = board.placeArrowSegments(arrow);
      }
    } else {
      var arrowIndex = 0;
      for (final cellData in boardDefinition.arrowCells) {
        final arrow = Arrow(
          id: Identifier('arrow-$arrowIndex-${id.value}'),
          position: cellData.position,
          direction: cellData.direction!,
        );
        board = board.placeArrow(arrow);
        arrowIndex++;
      }
    }

    playerStart.position.ensureWithinBounds(
      rows: boardDefinition.dimension.rows,
      columns: boardDefinition.dimension.columns,
    );

    return board;
  }

  /// Parsea un nivel desde el mapa JSON raíz.
  ///
  /// Requiere [optimalMoves] previamente calculado por [ShortestPathCalculator].
  factory Level.fromJson(
    Map<String, dynamic> json, {
    required int optimalMoves,
  }) {
    final idRaw = json['id'];
    if (idRaw is! String || idRaw.isEmpty) {
      throw const FormatException('Expected non-empty string for id.');
    }

    final difficultyRaw = json['difficulty'];
    if (difficultyRaw is! String) {
      throw const FormatException('Expected string for difficulty.');
    }

    final boardJson = json['board'];
    if (boardJson is! Map) {
      throw const FormatException('Expected object for board.');
    }

    final playerStartJson = json['playerStart'];
    if (playerStartJson is! Map) {
      throw const FormatException('Expected object for playerStart.');
    }

    final parMoves = json['parMoves'];
    if (parMoves is! int || parMoves <= 0) {
      throw const FormatException('Expected positive int for parMoves.');
    }

    final timeLimit = json['timeLimit'];
    if (timeLimit != null && timeLimit is! int) {
      throw const FormatException('Expected int or null for timeLimit.');
    }

    return Level(
      id: Identifier(idRaw),
      difficulty: _parseDifficulty(difficultyRaw),
      boardDefinition: LevelBoardDefinition.fromJson(
        Map<String, dynamic>.from(boardJson),
      ),
      playerStart: PlayerStart.fromJson(
        Map<String, dynamic>.from(playerStartJson),
      ),
      parMoves: parMoves,
      optimalMoves: optimalMoves,
      timeLimit: timeLimit,
    );
  }

  /// Serializa el nivel al formato JSON de definición.
  Map<String, dynamic> toJson() => {
        'id': id.value,
        'difficulty': difficulty.name,
        'board': boardDefinition.toJson(),
        'playerStart': playerStart.toJson(),
        'parMoves': parMoves,
        if (timeLimit != null) 'timeLimit': timeLimit,
      };

  static LevelDifficulty _parseDifficulty(String raw) {
    return LevelDifficulty.values.firstWhere(
      (d) => d.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => throw FormatException('Unknown difficulty: $raw'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Level &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          difficulty == other.difficulty &&
          parMoves == other.parMoves &&
          optimalMoves == other.optimalMoves;

  @override
  int get hashCode => Object.hash(id, difficulty, parMoves, optimalMoves);

  @override
  String toString() =>
      'Level(id: $id, difficulty: $difficulty, par: $parMoves, optimal: $optimalMoves)';
}
