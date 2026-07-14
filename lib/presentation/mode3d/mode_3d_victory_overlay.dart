import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/button_click.dart';

/// Overlay de victoria del Modo 3D: reintentar o volver al Home.
class Mode3dVictoryOverlay extends StatelessWidget {
  /// Crea el overlay con callbacks de [onRetry] y [onHome].
  const Mode3dVictoryOverlay({
    super.key,
    required this.onRetry,
    required this.onHome,
  });

  /// Reinicia el nivel 3D actual.
  final VoidCallback onRetry;

  /// Vuelve a la pantalla de inicio.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Material(
      key: const ValueKey('mode3d-victory-overlay'),
      color: AppColors.background.withValues(alpha: 0.82),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: AppColors.boardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sand),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 64, color: AppColors.success),
                  const SizedBox(height: 12),
                  Text(
                    strings.mode3dVictoryTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.mode3dVictoryMessage,
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('mode3d-victory-retry'),
                    onPressed: withButtonClick(context, onRetry),
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.mode3dRetry),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: AppColors.arrow,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const ValueKey('mode3d-victory-home'),
                    onPressed: withButtonClick(context, onHome),
                    icon: const Icon(Icons.home_outlined),
                    label: Text(strings.mode3dBackHome),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.gridLine),
                    ),
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
