import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/mode3d/mode_3d_victory_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should_call_retry_and_home_from_victory_overlay', (tester) async {
    var retried = false;
    var home = false;

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(
          home: Scaffold(
            body: Mode3dVictoryOverlay(
              onRetry: () => retried = true,
              onHome: () => home = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('mode3d-victory-retry')));
    await tester.pumpAndSettle();
    expect(retried, isTrue);

    await tester.tap(find.byKey(const ValueKey('mode3d-victory-home')));
    await tester.pumpAndSettle();
    expect(home, isTrue);
  });
}
