import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/settings/in_memory_app_settings.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/settings/app_settings_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/support/fake_repositories.dart';

void main() {
  testWidgets(
      'should_reset_seen_tutorial_flag_and_navigate_to_level_1_when_replay_tutorial_is_tapped',
      (tester) async {
    final settings = InMemoryAppSettings();
    await settings.setHasSeenTutorial(true);
    final controller = AppSettingsController(settings: settings);
    final level1 = buildTestLevel(id: 'level-1');
    final levelRepository = FakeLevelRepository([level1]);

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEn(),
        child: MaterialApp(
          home: SettingsScreen(
            settingsController: controller,
            levelRepository: levelRepository,
          ),
          onGenerateRoute: (routeSettings) {
            if (routeSettings.name == '/game') {
              final level = routeSettings.arguments as Level;
              return MaterialPageRoute(
                builder: (_) => Text('Game Screen for ${level.id.value}'),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.hasSeenTutorial, isTrue);

    await tester.tap(find.byKey(const ValueKey('settings-replay-tutorial')));
    await tester.pumpAndSettle();

    expect(controller.hasSeenTutorial, isFalse);
    expect(find.text('Game Screen for level-1'), findsOneWidget);
  });
}
