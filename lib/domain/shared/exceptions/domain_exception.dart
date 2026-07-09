/// Excepción base para errores de reglas de negocio en la capa de dominio.
///
/// Todas las excepciones específicas del dominio deben extender esta clase
/// para permitir un manejo uniforme en capas superiores.
class DomainException implements Exception {
  /// Crea una excepción de dominio con un [message] descriptivo.
  const DomainException(this.message);

  /// Mensaje legible que describe la violación de la regla de negocio.
  final String message;

  @override
  String toString() => 'DomainException: $message';
}
