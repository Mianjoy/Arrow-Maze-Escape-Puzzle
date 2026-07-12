import 'package:flutter/widgets.dart';

import '../../application/ports/i_audio_service.dart';

/// Expone [IAudioService] al árbol de widgets de presentación.
class AudioScope extends InheritedWidget {
  /// Crea el scope con el servicio de audio de la app.
  const AudioScope({
    super.key,
    required this.audioService,
    required super.child,
  });

  /// Servicio de reproducción de efectos y música.
  final IAudioService audioService;

  /// Devuelve el servicio de audio del ancestro más cercano.
  static IAudioService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AudioScope>();
    assert(scope != null, 'AudioScope not found in widget tree');
    return scope!.audioService;
  }

  @override
  bool updateShouldNotify(AudioScope oldWidget) =>
      oldWidget.audioService != audioService;
}
