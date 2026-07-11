/// Puerto de reproducción de efectos de sonido y música de fondo.
///
/// La implementación concreta respeta [IAppSettings.isMuted] sin que la UI
/// tenga que comprobar el flag en cada interacción.
abstract interface class IAudioService {
  /// Reproduce el clic de botones generales de la interfaz (navegación, formularios).
  Future<void> playButtonClick();

  /// Reproduce un sonido aleatorio cuando una flecha sale del tablero.
  Future<void> playArrowExtracted();

  /// Reproduce el sonido cuando una flecha choca con otra flecha.
  Future<void> playMovementNotAllowed();

  /// Reproduce el sonido de nivel completado (todas las flechas extraídas).
  Future<void> playLevelCleared();

  /// Reproduce el sonido de derrota al agotar movimientos.
  Future<void> playDefeat();

  /// Reproduce el sonido al agotar el tiempo del nivel.
  Future<void> playTimeUp();

  /// Inicia la música de fondo en bucle (si no está silenciado).
  Future<void> startBackgroundMusic();

  /// Detiene la música de fondo.
  Future<void> stopBackgroundMusic();
}
