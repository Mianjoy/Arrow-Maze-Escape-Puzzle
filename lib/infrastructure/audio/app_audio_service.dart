import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../../application/ports/i_app_settings.dart';
import '../../application/ports/i_audio_service.dart';

/// Reproduce efectos con [SystemSound] y música con [AudioPlayer] si hay assets.
///
/// Respeta [IAppSettings.isMuted] en cada llamada.
class AppAudioService implements IAudioService {
  /// Crea el servicio leyendo mute desde [settings].
  AppAudioService({required IAppSettings settings}) : _settings = settings;

  final IAppSettings _settings;
  final AudioPlayer _musicPlayer = AudioPlayer();
  bool _musicStarted = false;

  @override
  /// Sonido corto al tocar una celda.
  Future<void> playTap() async {
    if (_settings.isMuted) return;
    await SystemSound.play(SystemSoundType.click);
  }

  @override
  /// Sonido de victoria al limpiar el tablero.
  Future<void> playVictory() async {
    if (_settings.isMuted) return;
    await SystemSound.play(SystemSoundType.alert);
  }

  @override
  /// Sonido de derrota.
  Future<void> playDefeat() async {
    if (_settings.isMuted) return;
    await SystemSound.play(SystemSoundType.alert);
  }

  @override
  /// Inicia música de fondo en bucle desde assets (si existe el archivo).
  Future<void> startBackgroundMusic() async {
    if (_settings.isMuted || _musicStarted) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.35);
      await _musicPlayer.play(AssetSource('audio/background.mp3'));
      _musicStarted = true;
    } catch (_) {
      // Si el asset no está presente, la música se omite sin romper la app.
    }
  }

  @override
  /// Detiene la música de fondo.
  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
    _musicStarted = false;
  }

  /// Libera el reproductor de música (llamar al cerrar la app si aplica).
  Future<void> dispose() async {
    await _musicPlayer.dispose();
  }
}
