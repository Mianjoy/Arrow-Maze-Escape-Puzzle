import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/ports/i_audio_service.dart';
import 'audio_scope.dart';

IAudioService? _audioServiceOf(BuildContext context) {
  return context.getInheritedWidgetOfExactType<AudioScope>()?.audioService;
}

/// Reproduce el clic de botón y ejecuta [callback], si no es `null`.
VoidCallback? withButtonClick(BuildContext context, VoidCallback? callback) {
  if (callback == null) return null;
  return () {
    final audio = _audioServiceOf(context);
    if (audio != null) unawaited(audio.playButtonClick());
    callback();
  };
}

/// Reproduce el clic de botón y ejecuta [callback] async, si no es `null`.
Future<void> Function()? withButtonClickAsync(
  BuildContext context,
  Future<void> Function()? callback,
) {
  if (callback == null) return null;
  return () async {
    final audio = _audioServiceOf(context);
    if (audio != null) unawaited(audio.playButtonClick());
    await callback();
  };
}
