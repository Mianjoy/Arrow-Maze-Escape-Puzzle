import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../../application/ports/i_app_settings.dart';
import '../../application/ports/i_audio_service.dart';

/// Reproduce efectos desde assets MP3 y música de fondo con [AudioPlayer].
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

  static const _generalTap = 'audio/General_Tap/general_click_sound.mp3';
  static const _blockedMove = 'audio/Movement_Not_Allowe/not_allowed_movement.mp3';
  static const _levelCleared = 'audio/Level_Cleared/level_cleared.mp3';
  static const _timeUp = 'audio/times_up.mp3';
  static const _backgroundMusic = 'audio/background.mp3';

  static const _arrowExtractedSounds = [
    'audio/Tap_sound/tap_sound_1.mp3',
    'audio/Tap_sound/tap_sound_2.mp3',
    'audio/Tap_sound/tap_sound_3.mp3',
    'audio/Tap_sound/tap_sound_4.mp3',
    'audio/Tap_sound/tap_sound_5.mp3',
  ];

  @override
  /// Clic de botones generales de la interfaz.
  Future<void> playButtonClick() async {
    await _playSfx(_generalTap, fallback: SystemSoundType.click);
  }

  @override
  /// Sonido aleatorio cuando una flecha sale del tablero.
  Future<void> playArrowExtracted() async {
    if (_settings.isMuted) return;
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
  /// Sonido de derrota por movimientos agotados.
  Future<void> playDefeat() async {
    if (_settings.isMuted) return;
    await SystemSound.play(SystemSoundType.alert);
  }

  @override
  /// Sonido exclusivo al agotar el tiempo del nivel.
  Future<void> playTimeUp() async {
    await _playSfx(_timeUp);
  }

  @override
  /// Inicia música de fondo en bucle desde assets (si existe el archivo).
  ///
  /// Verifica primero que el asset exista vía [rootBundle]: en Flutter Web,
  /// `AudioPlayer.play()` con un archivo faltante falla de forma asíncrona
  /// dentro del elemento `<audio>` del navegador, fuera del try/catch de
  /// Dart, y aparece como una excepción no capturada en consola aunque no
  /// rompa la app. Comprobar el asset antes evita ese ruido.
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
      // Si falla la reproducción por otro motivo, la música se omite sin romper la app.
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
