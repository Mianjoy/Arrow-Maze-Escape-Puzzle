import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import 'arrow_path_geometry.dart';

/// Guía interactiva de dos pasos que se muestra sobre el tablero la primera
/// vez que alguien juega el nivel 1: en vez de leer instrucciones, la
/// persona aprende haciendo — se resalta la primera flecha con un anillo
/// pulsante hasta que la toca, y luego aparece un mensaje breve sobre la
/// meta del juego que se desvanece solo.
///
/// Pensado para adultos mayores y niños pequeños: texto mínimo, alto
/// contraste, y el avance depende de la acción real (tocar), no de botones
/// "Siguiente" que se puedan pulsar sin entender. Siempre se puede omitir.
class GameTutorialOverlay extends StatefulWidget {
  /// Crea el overlay para [board] con el tamaño de celda ya calculado.
  const GameTutorialOverlay({
    super.key,
    required this.board,
    required this.cellWidth,
    required this.cellHeight,
    required this.moveCount,
    required this.strings,
    required this.onDismiss,
  });

  /// Tablero actual (para ubicar la primera flecha activa).
  final Board board;

  /// Ancho de celda ya calculado por [BoardView].
  final double cellWidth;

  /// Alto de celda ya calculado por [BoardView].
  final double cellHeight;

  /// Movimientos hechos en la partida; avanza el tutorial al pasar de 0.
  final int moveCount;

  /// Cadenas localizadas.
  final AppStrings strings;

  /// Se invoca al terminar (paso 2 completo) u omitir el tutorial.
  final VoidCallback onDismiss;

  @override
  State<GameTutorialOverlay> createState() => _GameTutorialOverlayState();
}

class _GameTutorialOverlayState extends State<GameTutorialOverlay>
    with SingleTickerProviderStateMixin {
  static const _goalStepDuration = Duration(milliseconds: 2500);

  late final AnimationController _pulseController;
  bool _showGoalStep = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GameTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_showGoalStep && oldWidget.moveCount == 0 && widget.moveCount > 0) {
      setState(() => _showGoalStep = true);
      Future.delayed(_goalStepDuration, () {
        if (mounted) widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Atenúa el tablero para que el resaltado o el mensaje resalten;
        // no intercepta toques, el juego real sigue debajo.
        const Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Color(0x8A000000)),
          ),
        ),
        if (!_showGoalStep) ..._buildTapArrowStep() else _buildGoalStep(),
        Positioned(
          top: 8,
          right: 8,
          child: _SkipButton(label: widget.strings.tutorialSkip, onPressed: widget.onDismiss),
        ),
      ],
    );
  }

  List<Widget> _buildTapArrowStep() {
    final activeArrows = widget.board.activeArrows;
    if (activeArrows.isEmpty) return const [];
    final firstArrow = activeArrows.first;

    final center = ArrowPathGeometry.cellCenter(
      firstArrow.position,
      cellWidth: widget.cellWidth,
      cellHeight: widget.cellHeight,
    );

    return [
      AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final scale = 1 + (_pulseController.value * 0.35);
          final ringSize = (widget.cellWidth + widget.cellHeight) * 0.55 * scale;
          return Positioned(
            left: center.dx - ringSize / 2,
            top: center.dy - ringSize / 2,
            width: ringSize,
            height: ringSize,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.arrowActive, width: 4),
                ),
              ),
            ),
          );
        },
      ),
      Positioned(
        left: 16,
        right: 16,
        bottom: 24,
        child: IgnorePointer(
          child: _HintBubble(text: widget.strings.tutorialTapArrowHint),
        ),
      ),
    ];
  }

  Widget _buildGoalStep() {
    return Positioned(
      left: 16,
      right: 16,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(child: _HintBubble(text: widget.strings.tutorialGoalHint)),
      ),
    );
  }
}

/// Globo de texto de alto contraste para las pistas del tutorial.
class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 8)],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
      child: TextButton(
        key: const ValueKey('tutorial-skip'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        child: Text(label),
      ),
    );
  }
}
