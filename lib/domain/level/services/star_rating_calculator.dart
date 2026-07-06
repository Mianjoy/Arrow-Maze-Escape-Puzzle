import '../value_objects/star_rating.dart';
import '../../shared/exceptions/domain_exception.dart';

/// Servicio de dominio que calcula las estrellas obtenidas según movimientos usados.
///
/// - [optimalMoves]: ruta más corta (3 estrellas).
/// - [parMoves]: máximo permitido sin perder (1 estrella al completar en el límite).
/// - Entre ambos valores se interpola linealmente hacia 2 estrellas.
class StarRatingCalculator {
  /// Crea una instancia del calculador de estrellas.
  const StarRatingCalculator();

  /// Calcula las estrellas para [moveCount] dado el óptimo y el par del nivel.
  ///
  /// Lanza [DomainException] si [moveCount] supera [parMoves].
  StarRating calculate({
    required int moveCount,
    required int optimalMoves,
    required int parMoves,
  }) {
    if (moveCount > parMoves) {
      throw DomainException(
        'Cannot rate stars: move count ($moveCount) exceeds par ($parMoves).',
      );
    }

    if (moveCount <= optimalMoves) {
      return StarRating.three;
    }

    if (moveCount >= parMoves) {
      return StarRating.one;
    }

    final range = parMoves - optimalMoves;
    if (range <= 0) {
      return StarRating.three;
    }

    final excess = moveCount - optimalMoves;
    final ratio = excess / range;
    final stars = (3 - (ratio * 2)).round().clamp(1, 3);

    return StarRating(stars);
  }
}
