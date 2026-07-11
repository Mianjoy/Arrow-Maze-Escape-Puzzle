import '../../application/ports/i_audio_service.dart';

/// Implementación nula de audio para tests donde no se requiere sonido.
class NoOpAudioService implements IAudioService {
  /// No reproduce clic de botón.
  @override
  Future<void> playButtonClick() async {}

  /// No reproduce sonido de extracción de flecha.
  @override
  Future<void> playArrowExtracted() async {}

  /// No reproduce sonido de colisión entre flechas.
  @override
  Future<void> playMovementNotAllowed() async {}

  /// No reproduce sonido de nivel completado.
  @override
  Future<void> playLevelCleared() async {}

  /// No reproduce sonido de derrota por movimientos.
  @override
  Future<void> playDefeat() async {}

  /// No reproduce sonido de tiempo agotado.
  @override
  Future<void> playTimeUp() async {}

  /// No inicia música de fondo.
  @override
  Future<void> startBackgroundMusic() async {}

  /// No detiene música (no hay reproductor activo).
  @override
  Future<void> stopBackgroundMusic() async {}
}
