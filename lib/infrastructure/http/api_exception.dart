/// Excepción genérica para fallos de comunicación con la API REST.
///
/// Usada por los clientes HTTP de auth, progreso y leaderboard para
/// propagar mensajes legibles a la capa de presentación.
class ApiException implements Exception {
  /// Crea la excepción con un [message] descriptivo y opcional [statusCode].
  const ApiException(this.message, {this.statusCode});

  /// Descripción del error (mensaje del servidor o fallo de red).
  final String message;

  /// Código HTTP cuando la respuesta llegó al servidor.
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
