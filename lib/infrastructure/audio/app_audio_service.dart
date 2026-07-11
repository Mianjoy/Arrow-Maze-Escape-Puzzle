import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../../application/ports/i_app_settings.dart';
import '../../application/ports/i_audio_service.dart';

/// Reproduce efectos desde assets WAV y música de fondo con [AudioPlayer].
///
/// Respeta [IAppSettings.isMuted] en cada llamada.
class AppAudioService implements IAudioService {
  /// Crea el servicio leyendo mute desde [settings].
  AppAudioService({required IAppSettings settings}) : _settings = settings;

  final IAppSettings _settings;
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final Random _random = Random();
  bool _musicStarted = false;

  static const _generalTap = 'audio/General_Tap/general_click_sound.wav';
  static const _blockedMove = 'audio/Movement_Not_Allowe/not_allowed_movement.wav';
  static const _levelCleared = 'audio/Level_Cleared/level_cleared.wav';
  static const _timeUp = 'audio/times_up.wav';
  static const _noMovementsLeft = 'audio/no_movements_left.wav';
  static const _backgroundMusic = 'audio/background.wav';

  static const _arrowExtractedSounds = [
    'audio/Tap_sound/tap_sound_1.wav',
    'audio/Tap_sound/tap_sound_2.wav',
    'audio/Tap_sound/tap_sound_3.wav',
    'audio/Tap_sound/tap_sound_4.wav',
    'audio/Tap_sound/tap_sound_5.wav',
  ];

  @override
  /// Reintenta música de fondo tras un gesto del usuario (autoplay Web).
  Future<void> ensureAudioUnlocked() async {
    if (_settings.isMuted) return;
    await startBackgroundMusic();
  }

  @override
  /// Clic de botones generales de la interfaz.
  Future<void> playButtonClick() async {
    await _playSfx(_generalTap, fallback: SystemSoundType.click);
  }

  @override
  /// Sonido aleatorio cuando una flecha sale del tablero.
  Future<void> playArrowExtracted() async {
    final index = _random.nextInt(_arrowExtractedSounds.length);
    await _playSfx(_arrowExtractedSounds[index], fallback: SystemSoundType.click);
  }

  @override
  /// Sonido exclusivo cuando una flecha choca con otra flecha.
  Future<void> playMovementNotAllowed() async {
    await _playSfx(_blockedMove);
  }

  @override
  /// Sonido exclusivo al completar un nivel con éxito.
  Future<void> playLevelCleared() async {
    await _playSfx(_levelCleared);
  }

  @override
  /// Sonido exclusivo al agotar los movimientos del nivel.
  Future<void> playNoMovementsLeft() async {
    await _playSfx(_noMovementsLeft);
  }

  @override
  /// Sonido exclusivo al agotar el tiempo del nivel.
  Future<void> playTimeUp() async {
    await _playSfx(_timeUp);
  }

  @override
  /// Inicia música de fondo en bucle desde assets (si existe el archivo).
  Future<void> startBackgroundMusic() async {
    if (_settings.isMuted || _musicStarted) return;
    try {
      await rootBundle.load('assets/$_backgroundMusic');
    } catch (_) {
      return;
    }
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.35);
      await _musicPlayer.play(AssetSource(_backgroundMusic));
      _musicStarted = true;
    } catch (_) {
      // En Web el autoplay puede fallar hasta el primer gesto; _musicStarted
      // permanece false para que ensureAudioUnlocked pueda reintentar.
    }
  }

  @override
  /// Detiene la música de fondo.
  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
    _musicStarted = false;
  }

  /// Reproduce un efecto corto desde assets, con fallback opcional al sistema.
  Future<void> _playSfx(String assetPath, {SystemSoundType? fallback}) async {
    if (_settings.isMuted) return;
    try {
      await rootBundle.load('assets/$assetPath');
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (_) {
      if (fallback != null) {
        await SystemSound.play(fallback);
      }
    }
  }

  /// Libera los reproductores de audio (llamar al cerrar la app si aplica).
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
