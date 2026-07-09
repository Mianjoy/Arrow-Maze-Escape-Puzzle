import 'package:meta/meta.dart';

/// Value object que representa la calificación en estrellas de un nivel (1–3).
///
/// Se otorga al completar un nivel dentro del límite [parMoves].
@immutable
class StarRating {
  /// Crea una calificación con [value] entre 1 y 3.
  const StarRating(this.value)
      : assert(value >= 1 && value <= 3, 'Star rating must be between 1 and 3');

  /// Una estrella (desempeño mínimo aceptable dentro del par).
  static const one = StarRating(1);

  /// Dos estrellas (desempeño intermedio).
  static const two = StarRating(2);

  /// Tres estrellas (ruta óptima o muy cercana).
  static const three = StarRating(3);

  /// Cantidad de estrellas obtenidas (1, 2 o 3).
  final int value;

  /// Retorna la mejor calificación entre [current] y [other].
  static StarRating bestOf(StarRating? current, StarRating other) {
    if (current == null) return other;
    return current.value >= other.value ? current : other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StarRating && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'StarRating($value)';
}
