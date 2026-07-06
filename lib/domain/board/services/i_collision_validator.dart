import '../entities/board.dart';
import '../entities/arrow.dart';
import '../../shared/value_objects/position.dart';

/// Contrato del servicio de dominio que valida colisiones entre flechas.
///
/// Permite sustituir la implementación (p. ej. para pruebas) siguiendo
/// el principio de inversión de dependencias.
abstract interface class ICollisionValidator {
  /// Evalúa si [arrow] puede desplazarse en su dirección sin chocar
  /// con otra flecha activa en [board].
  ///
  /// Retorna la [Position] del bloqueo o `null` si el camino está libre
  /// hasta salir del tablero.
  Position? findBlockingPosition({
    required Board board,
    required Arrow arrow,
  });
}
