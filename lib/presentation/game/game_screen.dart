import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';
import '../navigation/app_route_observer.dart';
import '../result/result_screen_args.dart';
import 'game_controller.dart';
import '../widgets/app_nav_actions.dart';
import 'widgets/board_view.dart';
import 'game_time_formatter.dart';

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

class _GameScreenState extends State<GameScreen> with RouteAware {
  bool _resultNavigated = false;
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.startGame(widget.level);
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
    widget.controller.disposeController();
    super.dispose();
  }

  @override
  void didPushNext() {
    widget.controller.pauseGame();
  }

  @override
  void didPopNext() {
    widget.controller.resumeGame();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.level.displayLabel),
        actions: [
          AppNavActions(
            leaderboardLevelId: widget.level.id.value,
            leaderboardLevelTitle: widget.level.displayLabel,
          ),
        ],
      ),
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '${strings.movesLabel}: ${game.moveCount}/${game.level.parMoves} · '
                            '${strings.scoreLabel}: ${game.score}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        BoardGridToggleButton(
                          showGrid: _showGrid,
                          tooltip: _showGrid
                              ? strings.hideGridTooltip
                              : strings.showGridTooltip,
                          onPressed: () => setState(() => _showGrid = !_showGrid),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.timeRemainingLabel(
                          formatGameCountdown(game.remainingSeconds),
                          formatGameCountdown(game.level.playableTimeLimitSeconds),
                        ),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: game.isTimeRunningLow
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BoardView(
                  board: game.board,
                  showGrid: _showGrid,
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
