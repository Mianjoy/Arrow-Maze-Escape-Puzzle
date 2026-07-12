import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../application/ports/i_app_settings.dart';
import '../../application/ports/i_audio_service.dart';

/// Reproduce efectos desde assets MP3 y música de fondo con [AudioPlayer].
///
/// En Web se cargan bytes vía [rootBundle] (clave del manifest: `assets/audio/...`)
/// y se reproducen con [BytesSource], evitando HTTP 404 por doble prefijo
/// `assets/assets/` de [AssetSource].
///
/// [IAppSettings.isMuted] silencia solo la música de fondo (`background.mp3`).
/// [IAppSettings.isEffectsMuted] silencia todo el resto de sonidos del juego
/// (clic de botones, movimiento bloqueado, flecha extraída, victoria, derrota).
class AppAudioService implements IAudioService {
  /// Crea el servicio leyendo mute desde [settings].
  AppAudioService({required IAppSettings settings}) : _settings = settings {
    // Sin esto, cada `AudioPlayer` pide foco de audio exclusivo por defecto
    // en Android (`AndroidAudioFocus.gain`): al reproducir el clic de un
    // botón (un reproductor distinto al de la música), el sistema le quita
    // el foco al reproductor de música y lo detiene. `none` deja que todos
    // los sonidos de esta app convivan sin pisarse entre sí.
    final noFocusContext = AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    );
    unawaited(_musicPlayer.setAudioContext(noFocusContext));
    for (final player in _sfxPool) {
      player.setReleaseMode(ReleaseMode.stop);
      unawaited(player.setAudioContext(noFocusContext));
    }
  }

  static const _sfxPoolSize = 3;
  static const _mp3Mime = 'audio/mpeg';

  final IAppSettings _settings;
  final AudioPlayer _musicPlayer = AudioPlayer();
  final List<AudioPlayer> _sfxPool =
      List.generate(_sfxPoolSize, (_) => AudioPlayer());
  final Random _random = Random();
  final Map<String, Future<Uint8List>> _byteCache = {};

  bool _musicStarted = false;
  int _sfxPoolIndex = 0;

  /// Claves exactas del [AssetManifest] (incluyen prefijo `assets/`).
  static const _generalTap =
      'assets/audio/General_Tap/general_click_sound.mp3';
  static const _blockedMove =
      'assets/audio/Movement_Not_Allowe/not_allowed_movement.mp3';
  static const _levelCleared = 'assets/audio/Level_Cleared/level_cleared.mp3';
  static const _timeUp = 'assets/audio/times_up.mp3';
  static const _noMovementsLeft = 'assets/audio/no_movements_left.mp3';
  static const _backgroundMusic = 'assets/audio/background.mp3';

  static const _arrowExtractedSounds = [
    'assets/audio/Tap_sound/tap_sound_1.mp3',
    'assets/audio/Tap_sound/tap_sound_2.mp3',
    'assets/audio/Tap_sound/tap_sound_3.mp3',
    'assets/audio/Tap_sound/tap_sound_4.mp3',
    'assets/audio/Tap_sound/tap_sound_5.mp3',
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
  /// Inicia música de fondo en bucle (respeta el toggle de mute).
  Future<void> startBackgroundMusic() async {
    if (_settings.isMuted || _musicStarted) return;
    try {
      final bytes = await _loadAssetBytes(_backgroundMusic);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.35);
      await _musicPlayer.play(BytesSource(bytes, mimeType: _mp3Mime));
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

  /// Carga bytes del asset con caché (clave = ruta del manifest, p. ej. `assets/audio/...`).
  Future<Uint8List> _loadAssetBytes(String bundleKey) {
    return _byteCache.putIfAbsent(bundleKey, () async {
      final data = await rootBundle.load(bundleKey);
      return data.buffer.asUint8List();
    });
  }

  /// Reproduce un efecto corto con pool rotativo; respeta [IAppSettings.isEffectsMuted].
  Future<void> _playSfx(String bundleKey, {SystemSoundType? fallback}) async {
    if (_settings.isEffectsMuted) return;
    try {
      final bytes = await _loadAssetBytes(bundleKey);
      final player = _sfxPool[_sfxPoolIndex];
      _sfxPoolIndex = (_sfxPoolIndex + 1) % _sfxPool.length;
      await player.stop();
      await player.play(BytesSource(bytes, mimeType: _mp3Mime));
    } catch (_) {
      if (fallback != null && !kIsWeb) {
        await SystemSound.play(fallback);
      }
    }
  }

  /// Libera los reproductores de audio (llamar al cerrar la app si aplica).
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    for (final player in _sfxPool) {
      await player.dispose();
    }
  }
}
