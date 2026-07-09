import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';
import '../result/result_screen_args.dart';
import 'game_controller.dart';
import 'widgets/board_view.dart';

/// Pantalla de juego: tablero interactivo y navegación a victoria/derrota dedicadas.
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
  bool _resultNavigated = false;

  @override
  void initState() {
    super.initState();
    widget.controller.startGame(widget.level);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.level.id.value)),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final game = widget.controller.game;
          if (widget.controller.isLoading || game == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if ((game.isWon || game.isLost) && !_resultNavigated) {
            if (game.isWon && widget.controller.isSyncingProgress) {
              return const Center(child: CircularProgressIndicator());
            }
            _resultNavigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _openResultScreen(context, game));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${strings.movesLabel}: ${game.moveCount}/${game.level.parMoves} · '
                  '${strings.scoreLabel}: ${game.score}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: BoardView(
                  board: game.board,
                  onCellTapped: (position) {
                    _resultNavigated = false;
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

  /// Navega a la pantalla de victoria o derrota según el estado de [game].
  void _openResultScreen(BuildContext context, Game game) {
    if (game.isWon) {
      final result = widget.controller.lastVictoryResult;
      Navigator.of(context).pushReplacementNamed(
        '/victory',
        arguments: VictoryScreenArgs(
          game: game,
          nextLevel: result?.nextLevel,
          syncError: widget.controller.syncError,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      '/defeat',
      arguments: DefeatNavigationArgs(
        screenArgs: DefeatScreenArgs(game: game),
        gameController: widget.controller,
      ),
    );
  }
}
