import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../game/game_controller.dart';
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
      appBar: AppBar(title: Text(strings.defeatTitle)),
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
              onPressed: () async {
                await gameController.retry();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: Text(strings.retry),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.settings.name == '/levels'),
              child: Text(strings.backToLevels),
            ),
          ],
        ),
      ),
    );
  }
}
