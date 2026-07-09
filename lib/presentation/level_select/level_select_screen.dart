import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../auth/auth_session_controller.dart';
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

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  /// Cierra sesión y vuelve al inicio.
  Future<void> _logout() async {
    await widget.authSessionController.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
        ),
        actions: [
          if (username.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(username, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          IconButton(
            key: const ValueKey('logout-button'),
            tooltip: strings.signOut,
            onPressed: _logout,
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

          return ListView.builder(
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
                  color: unlocked ? Colors.green : Colors.grey,
                ),
                title: Text(level.id.value),
                subtitle: Text(
                  '${strings.difficultyLabel(level.difficulty.name)} · '
                  '${strings.parMovesLabel(level.parMoves)}'
                  '${completed && stars != null ? ' · ${strings.starsLabel(stars)}' : ''}'
                  '${!unlocked ? ' · ${strings.levelLocked}' : ''}',
                ),
                trailing: unlocked ? const Icon(Icons.play_arrow) : null,
                enabled: unlocked,
                onTap: unlocked
                    ? () => Navigator.of(context).pushNamed('/game', arguments: level)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
