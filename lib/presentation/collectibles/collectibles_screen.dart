import 'package:flutter/material.dart';

import '../../application/use_cases/get_player_progress_use_case.dart';
import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';
import '../widgets/app_nav_actions.dart';
import 'collectible_image.dart';

/// Pantalla que muestra la galería de coleccionables retro.
class CollectiblesScreen extends StatefulWidget {
  /// Crea la pantalla con acceso al progreso local del [playerId].
  const CollectiblesScreen({
    super.key,
    required this.getPlayerProgressUseCase,
    required this.playerId,
  });

  /// Caso de uso para leer el progreso persistido.
  final GetPlayerProgressUseCase getPlayerProgressUseCase;

  /// Jugador cuyos coleccionables se muestran.
  final Identifier playerId;

  @override
  State<CollectiblesScreen> createState() => _CollectiblesScreenState();
}

class _CollectiblesScreenState extends State<CollectiblesScreen> {
  PlayerProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await widget.getPlayerProgressUseCase.execute(widget.playerId);
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _isLoading = false;
    });
  }

  bool _isUnlocked(MetaCollectible collectible) {
    if (!collectible.isUnlockable) return false;
    return _progress?.hasCollectible(collectible.id) ?? false;
  }

  void _openDetail(AppStrings strings, MetaCollectible collectible) {
    final unlocked = _isUnlocked(collectible);
    final title = switch (collectible.kind) {
      MetaCollectibleKind.comingSoon => strings.collectibleComingSoonLabel,
      _ => unlocked
          ? strings.collectibleName(collectible.milestoneLevelNumber ?? 0)
          : strings.collectibleLockedLabel,
    };
    final subtitle = switch (collectible.kind) {
      MetaCollectibleKind.comingSoon => strings.collectibleComingSoonHint,
      MetaCollectibleKind.finalLevel => strings.collectibleFinalRequirement(
          MetaCollectibleCatalog.finalMilestoneLevelNumber,
        ),
      _ => strings.collectibleRequirement(collectible.milestoneLevelNumber ?? 0),
    };

    showCollectibleDetailDialog(
      context: context,
      collectible: collectible,
      title: title,
      subtitle: subtitle,
      locked: !unlocked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final unlockedCount = MetaCollectibleCatalog.all
        .where((item) => _progress?.hasCollectible(item.id) ?? false)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.collectiblesTitle),
        actions: const [AppNavActions(showCollectibles: false)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.collectiblesSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.collectiblesProgress(unlockedCount, MetaCollectibleCatalog.all.length),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: MetaCollectibleCatalog.galleryItems.length,
                      itemBuilder: (context, index) {
                        final collectible = MetaCollectibleCatalog.galleryItems[index];
                        final unlocked = _isUnlocked(collectible);
                        final locked = !unlocked;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey('collectible-${collectible.id}'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openDetail(strings, collectible),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: CollectibleImage(
                                  collectible: collectible,
                                  size: 72,
                                  locked: locked,
                                  showLockOverlay: locked,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
