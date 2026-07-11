import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

/// Acciones globales de navegación: clasificación y ajustes.
///
/// [leaderboardLevelId] opcional: si está presente, abre el ranking de ese nivel;
/// si no, abre el selector de niveles para elegir tabla.
class AppNavActions extends StatelessWidget {
  /// Crea los botones con [leaderboardLevelId] contextual opcional.
  const AppNavActions({super.key, this.leaderboardLevelId});

  /// Identificador de nivel para abrir su leaderboard directamente.
  final String? leaderboardLevelId;

  /// Navega a ajustes.
  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }

  /// Navega al hub de clasificación o al ranking de un nivel concreto.
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
        IconButton(
          key: const ValueKey('app-nav-leaderboard'),
          tooltip: strings.leaderboard,
          onPressed: () => _openLeaderboard(context),
          icon: const Icon(Icons.leaderboard_outlined),
        ),
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
