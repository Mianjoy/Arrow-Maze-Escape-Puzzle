import '../../application/ports/i_audio_service.dart';

/// Implementación nula de audio para tests donde no se requiere sonido.
class NoOpAudioService implements IAudioService {
  @override
  Future<void> ensureAudioUnlocked() async {}

  @override
  Future<void> playButtonClick() async {}

  @override
  Future<void> playArrowExtracted() async {}

  @override
  Future<void> playMovementNotAllowed() async {}

  @override
  Future<void> playLevelCleared() async {}

  @override
  Future<void> playNoMovementsLeft() async {}

  @override
  Future<void> playTimeUp() async {}

  @override
  Future<void> startBackgroundMusic() async {}

  @override
  Future<void> stopBackgroundMusic() async {}
}
