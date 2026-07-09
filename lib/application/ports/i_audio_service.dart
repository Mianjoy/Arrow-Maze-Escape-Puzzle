/// Puerto de reproducción de efectos de sonido y música de fondo.
///
/// La implementación concreta respeta [IAppSettings.isMuted] sin que la UI
/// tenga que comprobar el flag en cada interacción.
abstract interface class IAudioService {
  /// Reproduce un efecto corto al tocar una celda del tablero.
  Future<void> playTap();

  /// Reproduce el sonido de victoria al completar un nivel.
  Future<void> playVictory();

  /// Reproduce el sonido de derrota al agotar movimientos o tiempo.
  Future<void> playDefeat();

  /// Inicia la música de fondo en bucle (si no está silenciado).
  Future<void> startBackgroundMusic();

  /// Detiene la música de fondo.
  Future<void> stopBackgroundMusic();
}
