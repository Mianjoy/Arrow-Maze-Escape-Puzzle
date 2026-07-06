import '../../board/factories/board_factory.dart';
import '../../shared/exceptions/domain_exception.dart';
import '../aggregates/level.dart';
import '../services/shortest_path_calculator.dart';
import '../value_objects/level_board_definition.dart';
import '../value_objects/level_difficulty.dart';
import '../value_objects/player_start.dart';
import '../../shared/value_objects/identifier.dart';

/// Factory (patrón Factory) para crear instancias de [Level] desde JSON.
///
/// Orquesta el parseo del JSON, la construcción del tablero provisional
/// y el cálculo de la ruta óptima mediante [ShortestPathCalculator].
class LevelFactory {
  /// Crea la factory con dependencias inyectables.
  const LevelFactory({
    required ShortestPathCalculator shortestPathCalculator,
    BoardFactory? boardFactory,
  })  : _shortestPathCalculator = shortestPathCalculator,
        _boardFactory = boardFactory ?? const BoardFactory();

  final ShortestPathCalculator _shortestPathCalculator;
  final BoardFactory _boardFactory;

  /// Carga un [Level] completo desde el mapa JSON raíz del archivo de nivel.
  Level fromJson(Map<String, dynamic> json) {
    final provisional = _parseProvisional(json);
    final board = provisional.buildInitialBoard(boardFactory: _boardFactory);

    final optimalMoves = _shortestPathCalculator.calculateMinimumMoves(board);
    if (optimalMoves == null) {
      throw DomainException(
        'Level ${provisional.id.value} has no solvable path.',
      );
    }

    if (optimalMoves > provisional.parMoves) {
      throw DomainException(
        'Level ${provisional.id.value}: optimal moves ($optimalMoves) '
        'exceed parMoves (${provisional.parMoves}).',
      );
    }

    return Level(
      id: provisional.id,
      difficulty: provisional.difficulty,
      boardDefinition: provisional.boardDefinition,
      playerStart: provisional.playerStart,
      parMoves: provisional.parMoves,
      optimalMoves: optimalMoves,
      timeLimit: provisional.timeLimit,
    );
  }

  Level _parseProvisional(Map<String, dynamic> json) {
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
      difficulty: LevelDifficulty.values.firstWhere(
        (d) => d.name.toLowerCase() == difficultyRaw.toLowerCase(),
        orElse: () => throw FormatException('Unknown difficulty: $difficultyRaw'),
      ),
      boardDefinition: LevelBoardDefinition.fromJson(
        Map<String, dynamic>.from(boardJson),
      ),
      playerStart: PlayerStart.fromJson(
        Map<String, dynamic>.from(playerStartJson),
      ),
      parMoves: parMoves,
      optimalMoves: 1,
      timeLimit: timeLimit,
    );
  }
}
