import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';
import '../collectibles/collectible_image.dart';
import '../leaderboard/leaderboard_route_args.dart';
import '../widgets/app_nav_actions.dart';
import '../widgets/button_click.dart';
import '../result/result_screen_args.dart';

/// Pantalla dedicada de victoria con puntuación y opción de siguiente nivel.
class VictoryScreen extends StatelessWidget {
  /// Crea la pantalla con los [args] de la partida ganada.
  const VictoryScreen({super.key, required this.args});

  /// Datos de la victoria (partida, siguiente nivel, error de sync).
  final VictoryScreenArgs args;

  void _openCollectibleAnnouncement(BuildContext context) {
    openCollectiblesScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final game = args.game;
    final stars = game.starsEarned?.value ?? 0;
    final collectible = args.newlyUnlockedCollectible;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.victoryTitle),
        actions: [
          AppNavActions(
            leaderboardLevelId: game.level.id.value,
            leaderboardLevelTitle: game.level.displayLabel,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.emoji_events, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                strings.victoryTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${strings.scoreLabel}: ${game.score}',
                textAlign: TextAlign.center,
              ),
              Text(
                strings.starsLabel(stars),
                textAlign: TextAlign.center,
              ),
              if (collectible != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: InkWell(
                    key: const ValueKey('victory-collectible-announcement'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: withButtonClick(context, () => _openCollectibleAnnouncement(context)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CollectibleImage(
                            collectible: collectible,
                            size: 72,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.collectibleUnlockedMessage(
                                    collectible.milestoneLevelNumber ?? MetaCollectibleCatalog.finalMilestoneLevelNumber,
                                  ),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.collectibleTapToOpenGallery,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _syncMessage(strings),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              if (args.nextLevel != null)
                FilledButton(
                  key: const ValueKey('victory-next-level'),
                  onPressed: withButtonClick(
                    context,
                    () {
                      Navigator.of(context).pushReplacementNamed('/game', arguments: args.nextLevel);
                    },
                  ),
                  child: Text(strings.nextLevel),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: withButtonClick(
                  context,
                  () {
                    Navigator.of(context).pushNamed(
                      '/leaderboard',
                      arguments: LeaderboardRouteArgs(
                        levelId: game.level.id.value,
                        levelTitle: game.level.displayLabel,
                      ),
                    );
                  },
                ),
                child: Text(strings.leaderboard),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: withButtonClick(
                  context,
                  () => Navigator.of(context).pushNamedAndRemoveUntil(
                    '/levels',
                    (route) => route.settings.name == '/home',
                  ),
                ),
                child: Text(strings.backToLevels),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el mensaje de progreso local/remoto según [args.syncError].
  String _syncMessage(AppStrings strings) {
    if (args.syncError != null) {
      return strings.offlinePlayNotice;
    }
    return strings.progressSaved;
  }
}
