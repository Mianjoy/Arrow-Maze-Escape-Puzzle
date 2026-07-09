import 'package:meta/meta.dart';

/// Value object que encapsula un identificador único inmutable.
///
/// Se utiliza para referenciar entidades de dominio ([Player], [Arrow], [Game], etc.)
/// sin acoplar la capa de dominio a un mecanismo concreto de generación de IDs.
@immutable
class Identifier {
  /// Crea un identificador a partir de un [value] no vacío.
  ///
  /// Lanza [ArgumentError] si [value] está vacío o contiene solo espacios.
  const Identifier(this.value) : assert(value != '', 'Identifier value cannot be empty');

  /// Valor textual del identificador.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Identifier && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Identifier($value)';
}
