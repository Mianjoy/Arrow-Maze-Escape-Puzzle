import '../contract/level_contract.dart';
import '../domain/domain.dart';

/// Adaptador que traduce el contrato compartido [StructuredLevelJsonDto]
/// (wire format del backend) al agregado de dominio [Level].
///
/// Responsabilidades:
/// - Mapear campos del JSON de transporte a value objects de dominio.
/// - Construir un tablero provisional y calcular la ruta óptima con
///   [ShortestPathCalculator].
/// - Rechazar niveles irresolubles o cuya ruta óptima supere `maxMoves`.
///
/// Ubicación en Clean Architecture: capa **Interface Adapters**
/// (`lib/interface_adapters/`). El dominio no conoce este formato.
class LevelDtoMapper {
  /// Crea el mapper con dependencias inyectables (útil en tests).
  ///
  /// Si no se pasan, usa [ShortestPathCalculator] y [BoardFactory] por defecto
  /// con la misma configuración que el juego en producción.
  const LevelDtoMapper({
    ShortestPathCalculator? shortestPathCalculator,
    BoardFactory? boardFactory,
  })  : _shortestPathCalculator = shortestPathCalculator ??
            const ShortestPathCalculator(
              movementEngine: ArrowMovementEngine(
                collisionValidator: CollisionValidator(),
              ),
            ),
        _boardFactory = boardFactory ?? const BoardFactory();

  final ShortestPathCalculator _shortestPathCalculator;
  final BoardFactory _boardFactory;

  /// Construye un [Level] jugable a partir del DTO ya parseado.
  ///
  /// Pasos:
  /// 1. Traduce el DTO a un [Level] provisional (sin `optimalMoves` real).
  /// 2. Materializa el tablero inicial con [Level.buildInitialBoard].
  /// 3. Calcula movimientos mínimos con BFS ([ShortestPathCalculator]).
  /// 4. Valida solvabilidad y que `optimalMoves <= dto.maxMoves`.
  ///
  /// Lanza [DomainException] si el nivel no tiene solución o el par es
  /// demasiado bajo para la ruta óptima.
  Level fromDto(StructuredLevelJsonDto dto) {
    final provisional = _toProvisionalLevel(dto);
    final board = provisional.buildInitialBoard(boardFactory: _boardFactory);

    final optimalMoves = _shortestPathCalculator.calculateMinimumMoves(board);
    if (optimalMoves == null) {
      throw DomainException('Level ${dto.id} has no solvable path.');
    }

    if (optimalMoves > dto.maxMoves) {
      throw DomainException(
        'Level ${dto.id}: optimal moves ($optimalMoves) exceed maxMoves (${dto.maxMoves}).',
      );
    }

    return Level(
      id: provisional.id,
      levelNumber: provisional.levelNumber,
      difficulty: provisional.difficulty,
      boardDefinition: provisional.boardDefinition,
      playerStart: provisional.playerStart,
      parMoves: provisional.parMoves,
      optimalMoves: optimalMoves,
      timeLimit: provisional.timeLimit,
    );
  }

  /// Atajo: parsea un `Map` JSON (respuesta de `GET /levels/:id`) y devuelve [Level].
  ///
  /// Equivalente a `fromDto(StructuredLevelJsonDto.fromJson(json))`.
  Level fromJson(Map<String, dynamic> json) {
    return fromDto(StructuredLevelJsonDto.fromJson(json));
  }

  /// Traduce el DTO a un [Level] sin calcular aún la ruta óptima.
  ///
  /// Usa `optimalMoves: 1` como placeholder hasta que [fromDto] complete
  /// el agregado tras el BFS.
  Level _toProvisionalLevel(StructuredLevelJsonDto dto) {
    final exit = Position(row: dto.exit.row, column: dto.exit.col);
    final walls = (dto.walls ?? [])
        .map((w) => Position(row: w.row, column: w.col))
        .toList();

    final placements = dto.arrows
        .map(
          (arrow) => LevelArrowPlacement(
            id: Identifier(arrow.id),
            direction: _mapDirection(arrow.direction),
            head: Position(row: arrow.head.row, column: arrow.head.col),
            body: arrow.body
                .map((b) => Position(row: b.row, column: b.col))
                .toList(),
          ),
        )
        .toList();

    return Level(
      id: Identifier(dto.id),
      levelNumber: dto.levelNumber,
      difficulty: _mapDifficulty(dto.difficulty),
      boardDefinition: LevelBoardDefinition(
        dimension: BoardDimension(rows: dto.height, columns: dto.width),
        arrowPlacements: placements,
        walls: walls,
        exit: exit,
      ),
      // No hay avatar jugador en el wire format; reutilizamos `exit` como ancla.
      playerStart: PlayerStart(position: exit),
      parMoves: dto.maxMoves,
      optimalMoves: 1,
      timeLimit: dto.maxTimeInSeconds,
    );
  }

  /// Convierte [LevelDifficultyDto] (MAYÚSCULAS) a [LevelDifficulty] (dominio).
  static LevelDifficulty _mapDifficulty(LevelDifficultyDto dto) {
    return switch (dto) {
      LevelDifficultyDto.easy => LevelDifficulty.easy,
      LevelDifficultyDto.medium => LevelDifficulty.medium,
      LevelDifficultyDto.hard => LevelDifficulty.hard,
      LevelDifficultyDto.expert => LevelDifficulty.expert,
    };
  }

  /// Convierte [ArrowDirectionDto] a [Direction] del dominio.
  static Direction _mapDirection(ArrowDirectionDto dto) {
    return Direction(switch (dto) {
      ArrowDirectionDto.up => ArrowDirection.up,
      ArrowDirectionDto.down => ArrowDirection.down,
      ArrowDirectionDto.left => ArrowDirection.left,
      ArrowDirectionDto.right => ArrowDirection.right,
    });
  }
}
