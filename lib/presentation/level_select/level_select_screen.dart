import 'package:flutter/material.dart';

import '../auth/auth_session_controller.dart';
import 'level_select_controller.dart';

/// Pantalla de selección de nivel: lista niveles y navega a `/game`.
///
/// Muestra el usuario autenticado y permite cerrar sesión desde la barra superior.
class LevelSelectScreen extends StatefulWidget {
  /// Crea la pantalla con controladores de niveles y sesión.
  const LevelSelectScreen({
    super.key,
    required this.controller,
    required this.authSessionController,
  });

  /// Controlador que carga y expone los niveles.
  final LevelSelectController controller;

  /// Controlador de sesión para mostrar usuario y logout.
  final AuthSessionController authSessionController;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadLevels();
  }

  /// Cierra sesión y redirige al login.
  Future<void> _logout() async {
    await widget.authSessionController.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.authSessionController.session?.username ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrow Maze — Select Level'),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(username, style: Theme.of(context).textTheme.bodyMedium),
          )),
          IconButton(
            key: const ValueKey('logout-button'),
            tooltip: 'Sign out',
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
            return Center(
              child: Text('Could not load levels: ${widget.controller.error}'),
            );
          }

          final levels = widget.controller.levels;
          if (levels.isEmpty) {
            return const Center(child: Text('No levels available.'));
          }

          return ListView.builder(
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              return ListTile(
                key: ValueKey(level.id.value),
                title: Text(level.id.value),
                subtitle: Text(
                  'Difficulty: ${level.difficulty.name} · Par: ${level.parMoves} moves',
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: () => Navigator.of(context).pushNamed('/game', arguments: level),
              );
            },
          );
        },
      ),
    );
  }
}
