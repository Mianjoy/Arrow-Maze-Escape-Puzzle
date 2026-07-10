/// Puerto AOP para el aspecto de logging/trazabilidad de casos de uso.
///
/// Permite que un decorador (p. ej. [LoggingFireArrowUseCaseDecorator])
/// registre entrada/salida de un caso de uso sin que ni el caso de uso ni la
/// capa de presentación conozcan el mecanismo de logging concreto (consola,
/// archivo, servicio remoto, etc.) — el corte transversal vive detrás de
/// esta interfaz, no disperso en el código de negocio.
abstract interface class IUseCaseLogger {
  /// Registra un mensaje de trazabilidad.
  void log(String message);
}
