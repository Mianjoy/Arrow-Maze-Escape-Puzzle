import '../../application/ports/i_audio_service.dart';

/// Implementación nula de audio para tests donde no se requiere sonido.
class NoOpAudioService implements IAudioService {
  /// No reproduce ningún sonido al tocar una celda.
  @override
  Future<void> playTap() async {}

  /// No reproduce sonido de victoria.
  @override
  Future<void> playVictory() async {}

  /// No reproduce sonido de derrota.
  @override
  Future<void> playDefeat() async {}

  /// No inicia música de fondo.
  @override
  Future<void> startBackgroundMusic() async {}

  /// No detiene música (no hay reproductor activo).
  @override
  Future<void> stopBackgroundMusic() async {}
}
