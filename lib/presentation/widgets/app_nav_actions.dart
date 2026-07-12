import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../collectibles/collectible_image.dart';
import '../leaderboard/leaderboard_route_args.dart';
import 'button_click.dart';

/// Acciones globales de navegación: coleccionables, clasificación y ajustes.
///
/// [leaderboardLevelId] opcional: si está presente, abre el ranking de ese nivel;
/// si no, abre el selector de niveles para elegir tabla.
/// Use [showCollectibles], [showLeaderboard] y [showSettings] para ocultar iconos.
class AppNavActions extends StatelessWidget {
  /// Crea los botones con [leaderboardLevelId] contextual opcional.
  const AppNavActions({
    super.key,
    this.leaderboardLevelId,
    this.leaderboardLevelTitle,
    this.showCollectibles = true,
    this.showLeaderboard = true,
    this.showSettings = true,
  });

  /// Identificador de nivel para abrir su leaderboard directamente.
  final String? leaderboardLevelId;

  /// Nombre visible del nivel en el título del ranking.
  final String? leaderboardLevelTitle;

  /// Si es `false`, oculta el botón de coleccionables (p. ej. ya en esa pantalla).
  final bool showCollectibles;

  /// Si es `false`, oculta el botón de clasificación (p. ej. ya en leaderboard).
  final bool showLeaderboard;

  /// Si es `false`, oculta el botón de ajustes (p. ej. ya en settings).
  final bool showSettings;

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }

  void _openCollectibles(BuildContext context) {
    openCollectiblesScreen(context);
  }

  void _openLeaderboard(BuildContext context) {
    final levelId = leaderboardLevelId;
    Navigator.of(context).pushNamed(
      '/leaderboard',
      arguments: levelId == null
          ? null
          : LeaderboardRouteArgs(
              levelId: levelId,
              levelTitle: leaderboardLevelTitle,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCollectibles)
          IconButton(
            key: const ValueKey('app-nav-collectibles'),
            tooltip: strings.collectiblesTitle,
            onPressed: withButtonClick(context, () => _openCollectibles(context)),
            icon: const Icon(Icons.collections_bookmark_outlined),
          ),
        if (showLeaderboard)
          IconButton(
            key: const ValueKey('app-nav-leaderboard'),
            tooltip: strings.leaderboard,
            onPressed: withButtonClick(context, () => _openLeaderboard(context)),
            icon: const Icon(Icons.leaderboard_outlined),
          ),
        if (showSettings)
          IconButton(
            key: const ValueKey('app-nav-settings'),
            tooltip: strings.settingsTitle,
            onPressed: withButtonClick(context, () => _openSettings(context)),
            icon: const Icon(Icons.settings_outlined),
          ),
      ],
    );
  }
}
