import 'package:flutter/material.dart';

import 'leaderboard_controller.dart';

/// Pantalla que muestra el ranking de un nivel (`GET /leaderboard/:levelId`).
class LeaderboardScreen extends StatefulWidget {
  /// Crea la pantalla con [controller] y el [levelId] a consultar.
  const LeaderboardScreen({
    super.key,
    required this.controller,
    required this.levelId,
  });

  /// Controlador que carga las entradas del ranking.
  final LeaderboardController controller;

  /// Identificador del nivel cuyo top se muestra.
  final String levelId;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load(widget.levelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard — ${widget.levelId}')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.error != null) {
            return Center(
              child: Text('Could not load leaderboard: ${widget.controller.error}'),
            );
          }

          final entries = widget.controller.entries;
          if (entries.isEmpty) {
            return const Center(child: Text('No scores yet for this level.'));
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(entry.username),
                subtitle: Text(
                  'Score: ${entry.highScore} · Moves: ${entry.minMoves} · Time: ${entry.minTimeInSeconds}s',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
