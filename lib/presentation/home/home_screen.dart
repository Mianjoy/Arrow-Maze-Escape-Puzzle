import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../auth/auth_session_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/app_nav_actions.dart';
import '../widgets/button_click.dart';

/// Pantalla de inicio: título del juego, botón Jugar y acceso global.
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

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(strings.appTitle),
          actions: const [AppNavActions()],
        ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_on, size: 72, color: AppColors.arrow),
                const SizedBox(height: 24),
                Text(
                  strings.appTitle,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  key: const ValueKey('home-play'),
                  onPressed: withButtonClick(context, () => _onPlay(context)),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(strings.homePlay),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
