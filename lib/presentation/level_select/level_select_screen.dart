import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../auth/auth_session_controller.dart';
import '../theme/app_colors.dart';
import '../navigation/app_route_observer.dart';
import '../widgets/app_nav_actions.dart';
import '../widgets/button_click.dart';
import 'level_select_controller.dart';

/// Pantalla de selección de nivel con indicadores de bloqueo, estrellas y progreso.
class LevelSelectScreen extends StatefulWidget {
  /// Crea la pantalla con controladores de niveles y sesión.
  const LevelSelectScreen({
    super.key,
    required this.controller,
    required this.authSessionController,
  });

  /// Controlador que carga niveles y progreso local.
  final LevelSelectController controller;

  /// Controlador de sesión para logout.
  final AuthSessionController authSessionController;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    widget.controller.refreshProgress();
  }

  /// Cierra sesión y vuelve al inicio.
  Future<void> _logout() async {
    await widget.authSessionController.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  /// Pide al servidor el catálogo actualizado y muestra un SnackBar con el resultado.
  Future<void> _refreshLevels(AppStrings strings) async {
    final result = await widget.controller.refreshCatalog();
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.levelsRefreshFailed)),
      );
      return;
    }

    final message = result.hasNewLevels
        ? strings.levelsCatalogUpdated(result.newCount, result.addedCount)
        : strings.levelsRefreshedUpToDate(result.newCount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final username = widget.authSessionController.session?.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.levelSelectTitle),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: withButtonClick(
            context,
            () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('refresh-levels-button'),
            tooltip: strings.refreshLevelsTooltip,
            onPressed: widget.controller.isRefreshing
                ? null
                : withButtonClickAsync(context, () => _refreshLevels(strings)),
            icon: widget.controller.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          if (username.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(username, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          const AppNavActions(),
          IconButton(
            key: const ValueKey('logout-button'),
            tooltip: strings.signOut,
            onPressed: withButtonClickAsync(context, _logout),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.error != null) {
            return Center(child: Text('${widget.controller.error}'));
          }

          final levels = widget.controller.levels;
          if (levels.isEmpty) {
            return const Center(child: Text('No levels available.'));
          }

          final levelList = ListView.builder(
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              final unlocked = widget.controller.isLevelUnlocked(level);
              final completed = widget.controller.isLevelCompleted(level);
              final stars = widget.controller.starsFor(level);

              return ListTile(
                key: ValueKey(level.id.value),
                leading: Icon(
                  unlocked ? (completed ? Icons.check_circle : Icons.lock_open) : Icons.lock,
                  color: unlocked
                      ? (completed ? AppColors.success : AppColors.arrow)
                      : AppColors.gridLine,
                ),
                title: Text(level.displayLabel),
                subtitle: Text(
                  '${strings.difficultyLabel(level.difficulty.name)} · '
                  '${strings.parMovesLabel(level.parMoves)}'
                  '${completed && stars != null ? ' · ${strings.starsLabel(stars)}' : ''}'
                  '${!unlocked ? ' · ${strings.levelLocked}' : ''}',
                ),
                trailing: unlocked ? const Icon(Icons.play_arrow) : null,
                enabled: unlocked,
                onTap: unlocked
                    ? withButtonClick(
                        context,
                        () => Navigator.of(context).pushNamed('/game', arguments: level),
                      )
                    : null,
              );
            },
          );

          if (!widget.controller.isOffline) {
            return levelList;
          }

          // Banner de "modo sin conexión": el juego sigue jugable con el
          // progreso local; se sincronizará cuando vuelva la conexión.
          return Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.offlinePlayNotice,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: levelList),
            ],
          );
        },
      ),
    );
  }
}
