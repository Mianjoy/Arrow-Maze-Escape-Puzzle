import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../game/game_controller.dart';
import '../widgets/app_nav_actions.dart';
import '../result/result_screen_args.dart';

/// Pantalla dedicada de derrota con opción de reintentar el nivel.
class DefeatScreen extends StatelessWidget {
  /// Crea la pantalla con [args] y el [gameController] para reiniciar la partida.
  const DefeatScreen({
    super.key,
    required this.args,
    required this.gameController,
  });

  /// Partida perdida y metadatos.
  final DefeatScreenArgs args;

  /// Controlador para reiniciar el mismo nivel.
  final GameController gameController;

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final lossText = args.game.lossMessage?.text ?? strings.defeatMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.defeatTitle),
        actions: [
          AppNavActions(
            leaderboardLevelId: args.game.level.id.value,
            leaderboardLevelTitle: args.game.level.displayLabel,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              strings.defeatTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(lossText, textAlign: TextAlign.center),
            const Spacer(),
            FilledButton(
              key: const ValueKey('defeat-retry'),
              onPressed: () {
                // No usar `pop()`: todo el flujo Game→Victory→Game→...→Defeat
                // usa `pushReplacementNamed`, así que debajo de esta pantalla
                // sigue la instancia original de LevelSelectScreen (progreso
                // congelado desde antes de jugar este nivel), no la partida.
                // Reabrimos el mismo nivel con una ruta `/game` nueva (que
                // arranca su propio controlador en `initState`), igual que
                // el botón "siguiente nivel" de VictoryScreen.
                Navigator.of(context).pushReplacementNamed('/game', arguments: args.game.level);
              },
              child: Text(strings.retry),
            ),
            const SizedBox(height: 8),
            TextButton(
              // Ver comentario equivalente en VictoryScreen: fuerza una ruta
              // `/levels` nueva para no reusar un `LevelSelectController` con
              // progreso desactualizado.
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                '/levels',
                (route) => route.settings.name == '/home',
              ),
              child: Text(strings.backToLevels),
            ),
          ],
        ),
      ),
    );
  }
}
