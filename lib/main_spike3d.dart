import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'presentation/mode3d/mode_3d_screen.dart';

/// Entry point aislado para el Modo 3D (`three_js`).
///
/// Preferible desde la app: Home → Modo 3D (`/mode3d`).
/// Ejecutar con: flutter run -t lib/main_spike3d.dart
void main() {
  runApp(const Spike3DApp());
}

/// App mínima para lanzar solo el Modo 3D fuera del composition root.
class Spike3DApp extends StatelessWidget {
  /// Crea la app aislada del spike/modo 3D.
  const Spike3DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStringsScope(
      strings: const AppStringsEs(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Mode3DScreen(),
      ),
    );
  }
}
