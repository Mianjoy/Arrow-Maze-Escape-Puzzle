import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'game_controller.dart';
import 'widgets/board_view.dart';

/// Pantalla de juego: renderiza el tablero y reacciona a victoria/derrota.
///
/// Tras ganar, ofrece ver el leaderboard del nivel y muestra el estado de
/// sincronización de progreso con el backend.
class GameScreen extends StatefulWidget {
  /// Crea la pantalla con su [controller] y el [level] a jugar.
  const GameScreen({super.key, required this.controller, required this.level});

  /// Controlador que orquesta la partida.
  final GameController controller;

  /// Nivel que se está jugando.
  final Level level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _dialogShownForFinishedGame = false;

  @override
  void initState() {
    super.initState();
    widget.controller.startGame(widget.level);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.level.id.value)),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final game = widget.controller.game;
          if (widget.controller.isLoading || game == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if ((game.isWon || game.isLost) && !_dialogShownForFinishedGame) {
            _dialogShownForFinishedGame = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _showResultDialog(context, game));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Moves: ${game.moveCount}/${game.level.parMoves} · Score: ${game.score}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.controller.isSyncingProgress)
                const LinearProgressIndicator(),
              Expanded(
                child: BoardView(
                  board: game.board,
                  onCellTapped: (position) {
                    _dialogShownForFinishedGame = false;
                    widget.controller.onCellTapped(position);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Muestra el diálogo de resultado con opción de leaderboard si ganó.
  void _showResultDialog(BuildContext context, Game game) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(game.isWon ? 'Level cleared!' : 'Level failed'),
        content: Text(_buildDialogMessage(game)),
        actions: [
          if (game.isWon)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushNamed(
                  '/leaderboard',
                  arguments: game.level.id.value,
                );
              },
              child: const Text('Leaderboard'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to levels'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _dialogShownForFinishedGame = false;
              widget.controller.retry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Construye el mensaje del diálogo incluyendo estado de sync si aplica.
  String _buildDialogMessage(Game game) {
    if (!game.isWon) {
      return game.lossMessage?.text ?? 'You lost.';
    }

    final base = 'Score: ${game.score} · Stars: ${game.starsEarned?.value ?? 0}';
    final syncError = widget.controller.syncError;
    if (syncError != null) {
      return '$base\n\nProgress sync failed: $syncError';
    }
    if (widget.controller.isSyncingProgress) {
      return '$base\n\nSyncing progress...';
    }
    return '$base\n\nProgress saved.';
  }
}
