import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// En web, centra la app en un marco con proporción de teléfono móvil.
///
/// En Android, iOS y desktop nativos delega el layout sin restricciones extra.
class PhoneFrame extends StatelessWidget {
  /// Crea el marco alrededor de [child].
  const PhoneFrame({super.key, required this.child});

  /// Contenido de la aplicación (normalmente [MaterialApp]).
  final Widget child;

  static const _phoneWidth = 390.0;
  static const _phoneHeight = 844.0;
  static const _bezelRadius = 36.0;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    return ColoredBox(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = math.min(
              1.0,
              math.min(
                (constraints.maxWidth - 32) / _phoneWidth,
                (constraints.maxHeight - 32) / _phoneHeight,
              ),
            );

            return Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_bezelRadius),
                  border: Border.all(color: const Color(0xFF3D3D3D), width: 10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_bezelRadius - 4),
                  child: SizedBox(
                    width: _phoneWidth,
                    height: _phoneHeight,
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
