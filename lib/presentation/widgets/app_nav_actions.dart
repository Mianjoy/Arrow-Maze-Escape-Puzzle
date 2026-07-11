import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

/// Acciones globales de navegación: clasificación y ajustes.
///
/// [leaderboardLevelId] opcional: si está presente, abre el ranking de ese nivel;
/// si no, abre el selector de niveles para elegir tabla.
/// Use [showLeaderboard] y [showSettings] para ocultar el icono de la pantalla actual.
class AppNavActions extends StatelessWidget {
  /// Crea los botones con [leaderboardLevelId] contextual opcional.
  const AppNavActions({
    super.key,
    this.leaderboardLevelId,
    this.showLeaderboard = true,
    this.showSettings = true,
  });

  /// Identificador de nivel para abrir su leaderboard directamente.
  final String? leaderboardLevelId;

  /// Si es `false`, oculta el botón de clasificación (p. ej. ya en leaderboard).
  final bool showLeaderboard;

  /// Si es `false`, oculta el botón de ajustes (p. ej. ya en settings).
  final bool showSettings;

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }

  void _openLeaderboard(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/leaderboard',
      arguments: leaderboardLevelId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLeaderboard)
          IconButton(
            key: const ValueKey('app-nav-leaderboard'),
            tooltip: strings.leaderboard,
            onPressed: () => _openLeaderboard(context),
            icon: const Icon(Icons.leaderboard_outlined),
          ),
        if (showSettings)
          IconButton(
            key: const ValueKey('app-nav-settings'),
            tooltip: strings.settingsTitle,
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
      ],
    );
  }
}
