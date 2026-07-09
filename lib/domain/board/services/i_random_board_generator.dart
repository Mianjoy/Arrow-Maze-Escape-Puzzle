import '../entities/board.dart';
import '../value_objects/board_generation_config.dart';

/// Contrato para generadores procedurales de tableros.
///
/// La implementación concreta residirá en dominio o infraestructura según
/// la complejidad del algoritmo; el contrato permanece en dominio.
abstract interface class IRandomBoardGenerator {
  /// Genera un [Board] jugable según [config].
  Board generate(BoardGenerationConfig config);
}
