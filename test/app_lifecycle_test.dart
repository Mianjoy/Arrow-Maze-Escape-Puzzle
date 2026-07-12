import 'package:arrow_maze_escape_puzzle/application/ports/i_audio_service.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/settings/in_memory_app_settings.dart';
import 'package:arrow_maze_escape_puzzle/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'application/support/fake_repositories.dart';

/// Espía de [IAudioService] que solo cuenta llamadas a música de fondo.
class _SpyAudioService implements IAudioService {
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> startBackgroundMusic() async => startCalls++;

  @override
  Future<void> stopBackgroundMusic() async => stopCalls++;

  @override
  Future<void> ensureAudioUnlocked() async {}

  @override
  Future<void> playArrowExtracted() async {}

  @override
  Future<void> playButtonClick() async {}

  @override
  Future<void> playLevelCleared() async {}

  @override
  Future<void> playMovementNotAllowed() async {}

  @override
  Future<void> playNoMovementsLeft() async {}

  @override
  Future<void> playTimeUp() async {}
}

void main() {
  /// Regresión: sin un `WidgetsBindingObserver`, la música de fondo seguía
  /// sonando en Android al salir de la app (segundo plano) porque nada
  /// pausaba el `AudioPlayer` en transiciones de ciclo de vida.
  testWidgets(
      'should_pause_background_music_when_backgrounded_and_resume_when_foregrounded',
      (tester) async {
    final audioService = _SpyAudioService();
    final container = AppContainer(
      levelRepository: FakeLevelRepository(),
      audioService: audioService,
      enableProgressSync: false,
    );
    await container.appSettingsController.load();

    await tester.pumpWidget(ArrowMazeApp(container: container));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(audioService.stopCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(audioService.startCalls, 1);
  });

  testWidgets('should_not_resume_music_on_foreground_if_muted', (tester) async {
    final settings = InMemoryAppSettings();
    await settings.setMuted(true);
    final audioService = _SpyAudioService();
    final container = AppContainer(
      levelRepository: FakeLevelRepository(),
      appSettings: settings,
      audioService: audioService,
      enableProgressSync: false,
    );
    await container.appSettingsController.load();

    await tester.pumpWidget(ArrowMazeApp(container: container));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(audioService.startCalls, 0);
  });
}
