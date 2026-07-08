import 'dart:math';

import '../../shared/enums/arrow_direction.dart';
import '../../shared/value_objects/direction.dart';
import '../../shared/value_objects/identifier.dart';
import '../entities/board.dart';
import '../entities/arrow.dart';
import '../factories/board_factory.dart';
import '../value_objects/board_generation_config.dart';
import 'i_random_board_generator.dart';

/// Generador procedural básico de tableros con flechas aleatorias.
///
/// Coloca flechas en posiciones libres con direcciones aleatorias.
/// No garantiza solvabilidad; niveles diseñados manualmente pueden
/// reemplazar este generador en producción.
class RandomBoardGenerator implements IRandomBoardGenerator {
  /// Crea el generador con una [BoardFactory] inyectable.
  RandomBoardGenerator({BoardFactory? boardFactory})
      : _boardFactory = boardFactory ?? const BoardFactory();

  final BoardFactory _boardFactory;

  @override
  Board generate(BoardGenerationConfig config) {
    final random = Random(config.seed);
    final boardId = Identifier('board-${config.seed ?? random.nextInt(1 << 31)}');

    var board = _boardFactory.createEmpty(
      id: boardId,
      dimension: config.dimension,
    );

    final availablePositions = board.cells.map((c) => c.position).toList();
    final arrowCount = config.arrowCount.clamp(1, availablePositions.length);

    for (var i = 0; i < arrowCount; i++) {
      final index = random.nextInt(availablePositions.length);
      final position = availablePositions.removeAt(index);
      final direction = Direction(ArrowDirection.values[random.nextInt(4)]);
      final arrow = Arrow(
        id: Identifier('arrow-$i-${boardId.value}'),
        position: position,
        direction: direction,
      );
      board = board.placeArrow(arrow);
    }

    return board;
  }
}
