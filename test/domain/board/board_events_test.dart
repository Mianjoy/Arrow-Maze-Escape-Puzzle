import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

/// Pruebas del comportamiento portado desde la rama `Integracion`:
/// eventos de dominio del tablero (originalmente
/// `Tablero.consumirEventosDominio()`) y el caso "sin flecha"
/// (`ResultadoMovimiento.sinFlecha`).
void main() {
  const engine = ArrowMovementEngine(collisionValidator: CollisionValidator());

  /// Crea un tablero de prueba de 2x2 con las flechas indicadas.
  Board buildBoard(List<Arrow> arrows) {
    var board = const BoardFactory().createEmpty(
      id: const Identifier('board-test'),
      dimension: const BoardDimension(rows: 2, columns: 2),
    );
    for (final arrow in arrows) {
      board = board.placeArrow(arrow);
    }
    return board;
  }

  group('ArrowMovementEngine.attemptMove — domain events', () {
    test('should_emit_ArrowExtractedEvent_when_arrow_is_extracted', () {
      // Arrange: una flecha que puede salir del tablero sin obstáculos.
      const arrow = Arrow(
        id: Identifier('arrow-1'),
        position: Position(row: 0, column: 1),
        direction: Direction(ArrowDirection.right),
      );
      final board = buildBoard([arrow]);

      // Act
      final outcome = engine.attemptMove(board: board, arrowId: arrow.id);

      // Assert
      expect(outcome.result.isExtracted, isTrue);
      expect(outcome.board.domainEvents, hasLength(1));
      expect(outcome.board.domainEvents.single, isA<ArrowExtractedEvent>());
    });

    test('should_emit_ArrowBlockedEvent_when_arrow_is_blocked', () {
      // Arrange: una flecha bloqueadora fija y una flecha móvil hacia ella.
      const blocker = Arrow(
        id: Identifier('blocker'),
        position: Position(row: 0, column: 1),
        direction: Direction(ArrowDirection.up),
      );
      const mover = Arrow(
        id: Identifier('mover'),
        position: Position(row: 0, column: 0),
        direction: Direction(ArrowDirection.right),
      );
      final board = buildBoard([blocker, mover]);

      // Act
      final outcome = engine.attemptMove(board: board, arrowId: mover.id);

      // Assert
      expect(outcome.result.isBlocked, isTrue);
      expect(outcome.board.domainEvents, hasLength(1));
      expect(outcome.board.domainEvents.single, isA<ArrowBlockedEvent>());
    });

    test('should_drain_events_via_pullDomainEvents_and_return_clean_board', () {
      // Arrange
      const arrow = Arrow(
        id: Identifier('arrow-1'),
        position: Position(row: 0, column: 1),
        direction: Direction(ArrowDirection.right),
      );
      final board = buildBoard([arrow]);
      final outcome = engine.attemptMove(board: board, arrowId: arrow.id);

      // Act
      final drained = outcome.board.pullDomainEvents();

      // Assert
      expect(drained.events, hasLength(1));
      expect(drained.board.domainEvents, isEmpty);
    });
  });

  group('ArrowMovementEngine.attemptMoveAt — no arrow at cell', () {
    test('should_return_noArrowAtCell_when_tapped_cell_is_empty', () {
      // Arrange: tablero sin ninguna flecha.
      final board = buildBoard(const []);

      // Act
      final outcome = engine.attemptMoveAt(
        board: board,
        position: const Position(row: 1, column: 1),
      );

      // Assert
      expect(outcome.result.isNoArrowAtCell, isTrue);
      expect(outcome.board, same(board));
    });

    test('should_delegate_to_attemptMove_when_tapped_cell_has_arrow', () {
      // Arrange
      const arrow = Arrow(
        id: Identifier('arrow-1'),
        position: Position(row: 0, column: 1),
        direction: Direction(ArrowDirection.right),
      );
      final board = buildBoard([arrow]);

      // Act
      final outcome = engine.attemptMoveAt(
        board: board,
        position: arrow.position,
      );

      // Assert
      expect(outcome.result.isExtracted, isTrue);
    });
  });
}
