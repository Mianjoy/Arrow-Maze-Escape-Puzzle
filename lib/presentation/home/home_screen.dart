import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../auth/auth_session_controller.dart';

/// Pantalla de inicio: título del juego, botón Jugar y acceso a Ajustes.
class HomeScreen extends StatelessWidget {
  /// Crea la pantalla con el controlador de sesión para el flujo de Jugar.
  const HomeScreen({super.key, required this.authSessionController});

  /// Sesión usada para decidir si Jugar va a login o a niveles.
  final AuthSessionController authSessionController;

  /// Navega a niveles si hay sesión; si no, a login.
  void _onPlay(BuildContext context) {
    if (authSessionController.isAuthenticated) {
      Navigator.of(context).pushNamed('/levels');
    } else {
      Navigator.of(context).pushNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  strings.appTitle,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  key: const ValueKey('home-play'),
                  onPressed: () => _onPlay(context),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(strings.homePlay),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const ValueKey('home-settings'),
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                  icon: const Icon(Icons.settings),
                  label: Text(strings.homeSettings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
