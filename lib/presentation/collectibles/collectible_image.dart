import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';

/// Muestra la imagen de un coleccionable o un placeholder bloqueado.
class CollectibleImage extends StatelessWidget {
  /// Crea la vista del [collectible] con tamaño [size].
  const CollectibleImage({
    super.key,
    required this.collectible,
    this.size = 64,
    this.locked = false,
    this.showLockOverlay = false,
  });

  /// Definición del coleccionable a renderizar.
  final MetaCollectible collectible;

  /// Ancho y alto del recorte mostrado.
  final double size;

  /// Si es `true`, aplica filtro atenuado (coleccionable bloqueado).
  final bool locked;

  /// Si es `true` y [locked], superpone un candado.
  final bool showLockOverlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildContent(context),
            if (showLockOverlay && locked)
              Center(
                child: Icon(
                  Icons.lock,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: size * 0.35,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (collectible.kind == MetaCollectibleKind.comingSoon) {
      return _ComingSoonPlaceholder(size: size);
    }

    final assetPath = collectible.assetPath;
    if (assetPath == null) {
      return _ComingSoonPlaceholder(size: size);
    }

    return ColorFiltered(
      colorFilter: locked
          ? const ColorFilter.matrix(<double>[
              0.15, 0.15, 0.15, 0, 0,
              0.15, 0.15, 0.15, 0, 0,
              0.15, 0.15, 0.15, 0, 0,
              0, 0, 0, 1, 0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (context, error, stackTrace) => _ComingSoonPlaceholder(size: size),
      ),
    );
  }
}

class _ComingSoonPlaceholder extends StatelessWidget {
  const _ComingSoonPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, color: Colors.white70, size: size * 0.28),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              strings.collectibleComingSoonLabel,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: size * 0.11,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Muestra un coleccionable ampliado en un diálogo modal.
Future<void> showCollectibleDetailDialog({
  required BuildContext context,
  required MetaCollectible collectible,
  required String title,
  required String subtitle,
  required bool locked,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CollectibleImage(
              collectible: collectible,
              size: 160,
              locked: locked,
              showLockOverlay: locked,
            ),
            const SizedBox(height: 12),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      );
    },
  );
}

/// Navega a la pantalla de coleccionables.
void openCollectiblesScreen(BuildContext context) {
  Navigator.of(context).pushNamed('/collectibles');
}
