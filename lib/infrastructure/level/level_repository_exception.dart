/// Error de la capa de infraestructura al cargar niveles desde una fuente externa.
///
/// Envuelve fallos de red, respuestas HTTP inesperadas o JSON inválido
/// sin filtrar detalles de transporte al dominio ([DomainException] queda
/// reservado a reglas de negocio dentro de [LevelDtoMapper]).
class LevelRepositoryException implements Exception {
  /// Crea la excepción con un [message] legible y el [statusCode] HTTP si aplica.
  const LevelRepositoryException(this.message, {this.statusCode});

  /// Descripción del fallo (timeout, 500, cuerpo no JSON, etc.).
  final String message;

  /// Código de estado HTTP cuando el servidor respondió; `null` si fue error de red.
  final int? statusCode;

  @override
  String toString() {
    if (statusCode != null) {
      return 'LevelRepositoryException($statusCode): $message';
    }
    return 'LevelRepositoryException: $message';
  }
}
