import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

/// Pruebas del comportamiento portado desde la rama `Integracion`:
/// `Arrow.reset()` (originalmente `Flecha.reiniciar()`).
void main() {
  group('Arrow.reset', () {
    test('restaura la posición original y deja la flecha activa', () {
      // Arrange: una flecha bloqueada, lejos de su posición original.
      const originalPosition = Position(row: 0, column: 0);
      const arrow = Arrow(
        id: Identifier('arrow-1'),
        position: Position(row: 3, column: 3),
        direction: Direction(ArrowDirection.up),
        state: ArrowState.blocked,
      );

      // Act: se reinicia la flecha a su posición original.
      final result = arrow.reset(originalPosition: originalPosition);

      // Assert: vuelve a estar activa en la posición original.
      expect(result.position, originalPosition);
      expect(result.state, ArrowState.active);
      expect(result.isMovable, isTrue);
    });

    test('también reinicia una flecha ya extraída', () {
      // Arrange
      const originalPosition = Position(row: 1, column: 2);
      const arrow = Arrow(
        id: Identifier('arrow-2'),
        position: Position(row: 0, column: 2),
        direction: Direction(ArrowDirection.left),
        state: ArrowState.extracted,
      );

      // Act
      final result = arrow.reset(originalPosition: originalPosition);

      // Assert
      expect(result.state, ArrowState.active);
      expect(result.isExtracted, isFalse);
    });
  });
}
