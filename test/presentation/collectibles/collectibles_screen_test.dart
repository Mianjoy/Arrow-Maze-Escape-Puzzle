import 'package:arrow_maze_escape_puzzle/application/use_cases/get_player_progress_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/progress/in_memory_player_progress_repository.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/collectibles/collectibles_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should_show_collectible_grid_and_unlocked_progress', (tester) async {
    const playerId = Identifier('p-collectibles');
    final repository = InMemoryPlayerProgressRepository();
    await repository.save(
      PlayerProgress(
        playerId: playerId,
        unlockedCollectibles: {'collectible-milestone-2'},
      ),
    );

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(
          home: CollectiblesScreen(
            getPlayerProgressUseCase: GetPlayerProgressUseCase(progressRepository: repository),
            playerId: playerId,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1 / 11 desbloqueados'), findsOneWidget);
    expect(find.byKey(const ValueKey('collectible-collectible-milestone-2')), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(MetaCollectibleCatalog.galleryItems, hasLength(14));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('collectible-collectible-coming-soon-3')),
      120,
    );
    expect(find.text('Próximamente'), findsNWidgets(3));
  });

  testWidgets('should_open_detail_dialog_when_tapping_unlocked_collectible', (tester) async {
    const playerId = Identifier('p-collectibles-dialog');
    final repository = InMemoryPlayerProgressRepository();
    await repository.save(
      PlayerProgress(
        playerId: playerId,
        unlockedCollectibles: {'collectible-milestone-2'},
      ),
    );

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(
          home: CollectiblesScreen(
            getPlayerProgressUseCase: GetPlayerProgressUseCase(progressRepository: repository),
            playerId: playerId,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collectible-collectible-milestone-2')));
    await tester.pumpAndSettle();

    expect(find.text(const AppStringsEs().collectibleName(2)), findsOneWidget);
  });
}
