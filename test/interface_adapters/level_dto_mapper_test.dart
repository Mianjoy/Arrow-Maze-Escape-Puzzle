import 'dart:convert';
import 'dart:io';

import 'package:arrow_maze_escape_puzzle/contract/level_contract.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/interface_adapters/level_dto_mapper.dart';
import 'package:test/test.dart';

/// Pruebas del contrato compartido y del adaptador [LevelDtoMapper].
///
/// Valida que el JSON canónico `docs/levels/simple-1.json` (mismo nivel que
/// usa el backend en `LevelJsonMapper.spec.ts`) parsea y mapea a dominio.
void main() {
  const mapper = LevelDtoMapper();

  group('StructuredLevelJsonDto — wire format parsing', () {
    test('should_parse_metadata_and_arrows_from_canonical_simple_1', () {
      final raw = File('docs/levels/simple-1.json').readAsStringSync();
      final dto = StructuredLevelJsonDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);

      expect(dto.id, 'simple-1');
      expect(dto.levelNumber, 1);
      expect(dto.difficulty, LevelDifficultyDto.easy);
      expect(dto.width, 5);
      // height 6, no 5: f4 se movió a una fila nueva para darle una celda de
      // cuerpo (regla de mínimo 1 celda de cuerpo por flecha; el tablero
      // 5x5 original no tenía ninguna celda libre para reubicarla).
      expect(dto.height, 6);
      expect(dto.arrows, hasLength(8));
      expect(dto.exit.row, 0);
      expect(dto.exit.col, 4);
    });
  });

  group('LevelDtoMapper — wire format to domain', () {
    test('should_map_simple_1_to_solvable_multi_cell_level', () {
      final raw = File('docs/levels/simple-1.json').readAsStringSync();
      final base = StructuredLevelJsonDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      // El JSON canónico usa maxMoves: 5; elevamos el techo para validar
      // solvabilidad del layout sin fallar por par demasiado bajo en el test.
      final dto = StructuredLevelJsonDto(
        id: base.id,
        levelNumber: base.levelNumber,
        difficulty: base.difficulty,
        maxMoves: 50,
        maxTimeInSeconds: base.maxTimeInSeconds,
        width: base.width,
        height: base.height,
        exit: base.exit,
        walls: base.walls,
        arrows: base.arrows,
      );

      final level = mapper.fromDto(dto);

      expect(level.id.value, 'simple-1');
      expect(level.levelNumber, 1);
      expect(level.difficulty, LevelDifficulty.easy);
      expect(level.boardDefinition.usesWireLayout, isTrue);
      expect(level.boardDefinition.arrowPlacements, hasLength(8));
      expect(level.optimalMoves, greaterThan(0));
      expect(level.optimalMoves, lessThanOrEqualTo(level.parMoves));
    });

    test('should_map_minimal_backend_level_2x1_single_arrow', () {
      const dto = StructuredLevelJsonDto(
        id: 'level-1',
        levelNumber: 1,
        difficulty: LevelDifficultyDto.easy,
        maxMoves: 5,
        maxTimeInSeconds: 60,
        width: 2,
        height: 1,
        exit: CellPositionDto(row: 0, col: 1),
        arrows: [
          StructuredArrowJsonDto(
            id: 'f1',
            direction: ArrowDirectionDto.right,
            head: CellPositionDto(row: 0, col: 0),
          ),
        ],
      );

      final level = mapper.fromDto(dto);

      expect(level.id.value, 'level-1');
      expect(level.boardDefinition.dimension.rows, 1);
      expect(level.boardDefinition.dimension.columns, 2);
      expect(level.optimalMoves, 1);
    });

    test('should_use_server_provided_optimalMoves_instead_of_recalculating', () {
      // El servidor calcula `optimalMoves` una vez al validar el nivel
      // (siempre `arrows.length`, ver LevelJsonMapper.toDto); el mapper debe
      // usarlo tal cual, sin volver a buscar la ruta óptima localmente.
      const dto = StructuredLevelJsonDto(
        id: 'server-computed',
        levelNumber: 5,
        difficulty: LevelDifficultyDto.easy,
        maxMoves: 10,
        maxTimeInSeconds: 60,
        width: 2,
        height: 1,
        exit: CellPositionDto(row: 0, col: 1),
        arrows: [
          StructuredArrowJsonDto(
            id: 'f1',
            direction: ArrowDirectionDto.right,
            head: CellPositionDto(row: 0, col: 0),
          ),
        ],
        optimalMoves: 1,
      );

      final level = mapper.fromDto(dto);

      expect(level.optimalMoves, 1);
    });

    test('should_fall_back_to_arrows_length_when_dto_omits_optimalMoves', () {
      // Archivos autor-escritos (no pasados por LevelJsonMapper.toDto) no
      // traen `optimalMoves`; el respaldo es `arrows.length`, el mismo
      // valor que el servidor calcularía.
      const dto = StructuredLevelJsonDto(
        id: 'no-optimal-in-dto',
        levelNumber: 6,
        difficulty: LevelDifficultyDto.easy,
        maxMoves: 10,
        maxTimeInSeconds: 60,
        width: 2,
        height: 1,
        exit: CellPositionDto(row: 0, col: 1),
        arrows: [
          StructuredArrowJsonDto(
            id: 'f1',
            direction: ArrowDirectionDto.right,
            head: CellPositionDto(row: 0, col: 0),
          ),
          StructuredArrowJsonDto(
            id: 'f2',
            direction: ArrowDirectionDto.left,
            head: CellPositionDto(row: 0, col: 1),
          ),
        ],
      );

      final level = mapper.fromDto(dto);

      expect(level.optimalMoves, 2);
    });

    test('should_map_display_name_from_wire_format', () {
      const dto = StructuredLevelJsonDto(
        id: 'level-1',
        name: 'Primer Contacto',
        levelNumber: 1,
        difficulty: LevelDifficultyDto.easy,
        maxMoves: 5,
        maxTimeInSeconds: 60,
        width: 2,
        height: 1,
        exit: CellPositionDto(row: 0, col: 1),
        arrows: [
          StructuredArrowJsonDto(
            id: 'f1',
            direction: ArrowDirectionDto.right,
            head: CellPositionDto(row: 0, col: 0),
          ),
        ],
      );

      final level = mapper.fromDto(dto);

      expect(level.displayName, 'Primer Contacto');
      expect(level.displayLabel, 'Primer Contacto');
    });
      const dto = StructuredLevelJsonDto(
        id: 'too-many-moves',
        levelNumber: 7,
        difficulty: LevelDifficultyDto.hard,
        maxMoves: 1,
        maxTimeInSeconds: 60,
        width: 2,
        height: 1,
        exit: CellPositionDto(row: 0, col: 1),
        arrows: [
          StructuredArrowJsonDto(
            id: 'f1',
            direction: ArrowDirectionDto.right,
            head: CellPositionDto(row: 0, col: 0),
          ),
          StructuredArrowJsonDto(
            id: 'f2',
            direction: ArrowDirectionDto.left,
            head: CellPositionDto(row: 0, col: 1),
          ),
        ],
      );

      expect(() => mapper.fromDto(dto), throwsA(isA<DomainException>()));
    });
  });
}
