import '../contract/level_contract.dart';
import '../domain/domain.dart';

/// Adaptador que traduce el contrato compartido [StructuredLevelJsonDto]
/// (wire format del backend) al agregado de dominio [Level].
///
/// Responsabilidades:
/// - Mapear campos del JSON de transporte a value objects de dominio.
/// - Tomar `optimalMoves` del DTO (calculado por el servidor) en vez de
///   recalcularlo — ver nota en [fromDto].
/// - Rechazar niveles cuya ruta óptima supere `maxMoves`.
///
/// Ubicación en Clean Architecture: capa **Interface Adapters**
/// (`lib/interface_adapters/`). El dominio no conoce este formato.
class LevelDtoMapper {
  /// Crea el mapper (sin estado ni dependencias inyectables).
  const LevelDtoMapper();

  /// Construye un [Level] jugable a partir del DTO ya parseado.
  ///
  /// `optimalMoves` se toma de `dto.optimalMoves` (calculado por el backend
  /// en `LevelJsonMapper.toDto`, ver `docs/contract/level.contract.ts`) en
  /// vez de recalcularse con búsqueda local: cada disparo exitoso retira
  /// exactamente una flecha y ganar exige retirarlas todas, así que el
  /// óptimo es siempre `arrows.length` — no hace falta ninguna búsqueda para
  /// derivarlo, y antes de este cambio se recalculaba con un BFS sobre el
  /// espacio de estados que, para niveles con muchas flechas (ej. 48),
  /// podía congelar la pestaña completa al cargar el catálogo (ver
  /// AI_USAGE.md). Si el DTO no trae `optimalMoves` (archivo autor-escrito
  /// sin pasar por el backend), se usa `arrows.length` como respaldo, que es
  /// matemáticamente el mismo valor.
  ///
  /// Lanza [DomainException] si el par (`maxMoves`) es demasiado bajo para
  /// la ruta óptima.
  Level fromDto(StructuredLevelJsonDto dto) {
    final provisional = _toProvisionalLevel(dto);
    final optimalMoves = dto.optimalMoves ?? dto.arrows.length;

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

  /// Traduce el DTO a un [Level] con `optimalMoves: 1` como placeholder;
  /// [fromDto] lo reemplaza por el valor real antes de devolverlo.
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
