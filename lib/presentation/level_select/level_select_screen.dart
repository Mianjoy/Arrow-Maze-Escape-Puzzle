import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'level_select_controller.dart';

/// Pantalla de selección de nivel: lista los niveles disponibles y navega
/// a `/game` con el [Level] elegido como argumento de ruta.
class LevelSelectScreen extends StatefulWidget {
  /// Crea la pantalla con su [controller].
  const LevelSelectScreen({super.key, required this.controller});

  /// Controlador que carga y expone los niveles.
  final LevelSelectController controller;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadLevels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arrow Maze — Select Level')),
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
                subtitle: Text('Difficulty: ${level.difficulty.name} · Par: ${level.parMoves} moves'),
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
