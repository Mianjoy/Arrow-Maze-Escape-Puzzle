import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../result/result_screen_args.dart';

/// Pantalla dedicada de victoria con puntuación y opción de siguiente nivel.
class VictoryScreen extends StatelessWidget {
  /// Crea la pantalla con los [args] de la partida ganada.
  const VictoryScreen({super.key, required this.args});

  /// Datos de la victoria (partida, siguiente nivel, error de sync).
  final VictoryScreenArgs args;

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final game = args.game;
    final stars = game.starsEarned?.value ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(strings.victoryTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              strings.victoryTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${strings.scoreLabel}: ${game.score}',
              textAlign: TextAlign.center,
            ),
            Text(
              strings.starsLabel(stars),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _syncMessage(strings),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            if (args.nextLevel != null)
              FilledButton(
                key: const ValueKey('victory-next-level'),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/game', arguments: args.nextLevel);
                },
                child: Text(strings.nextLevel),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/leaderboard',
                  arguments: game.level.id.value,
                );
              },
              child: Text(strings.leaderboard),
            ),
            const SizedBox(height: 8),
            TextButton(
              // `pushNamedAndRemoveUntil` (no `popUntil`) fuerza una ruta
              // `/levels` nueva con un `LevelSelectController` recién creado,
              // así el progreso recién ganado se refleja sin volver al home.
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

  /// Construye el mensaje de progreso local/remoto según [args.syncError].
  ///
  /// Ante un fallo de sincronización se muestra el aviso amable de "modo sin
  /// conexión" (el progreso ya quedó guardado localmente y se reintentará),
  /// no el error técnico de red.
  String _syncMessage(AppStrings strings) {
    if (args.syncError != null) {
      return strings.offlinePlayNotice;
    }
    return strings.progressSaved;
  }
}
