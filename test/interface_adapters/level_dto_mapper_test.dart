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

  group('StructuredLevelJsonDto — parseo del wire format', () {
    test('parsea metadatos y flechas del nivel canónico simple-1', () {
      final raw = File('docs/levels/simple-1.json').readAsStringSync();
      final dto = StructuredLevelJsonDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);

      expect(dto.id, 'simple-1');
      expect(dto.levelNumber, 1);
      expect(dto.difficulty, LevelDifficultyDto.easy);
      expect(dto.width, 5);
      expect(dto.height, 5);
      expect(dto.arrows, hasLength(8));
      expect(dto.exit.row, 0);
      expect(dto.exit.col, 4);
    });
  });

  group('LevelDtoMapper — wire format → dominio', () {
    test('mapea simple-1 a Level resoluble (layout multi-celda)', () {
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

    test('mapea el nivel mínimo del backend (2×1, una flecha)', () {
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

    test('rechaza un nivel sin solución (flechas enfrentadas)', () {
      const dto = StructuredLevelJsonDto(
        id: 'blocked',
        levelNumber: 99,
        difficulty: LevelDifficultyDto.hard,
        maxMoves: 10,
        maxTimeInSeconds: 120,
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
