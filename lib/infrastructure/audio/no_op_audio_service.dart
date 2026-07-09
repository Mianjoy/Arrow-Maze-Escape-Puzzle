import '../../application/ports/i_audio_service.dart';

/// Implementación nula de audio para tests donde no se requiere sonido.
class NoOpAudioService implements IAudioService {
  @override
  Future<void> playTap() async {}

  @override
  Future<void> playVictory() async {}

  @override
  Future<void> playDefeat() async {}

  @override
  Future<void> startBackgroundMusic() async {}

  @override
  Future<void> stopBackgroundMusic() async {}
}
