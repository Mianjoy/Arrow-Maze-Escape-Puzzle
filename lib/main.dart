import 'package:flutter/material.dart';

/// Punto de entrada de la aplicación móvil Arrow-Maze.
/// La UI se implementará en la capa de Arquitectura; el dominio ya está listo.
void main() {
  runApp(const ArrowMazeApp());
}

/// Widget raíz de la aplicación Arrow-Maze.
///
/// Por ahora solo muestra una pantalla de marcador de posición; las
/// pantallas reales (inicio, selección de nivel, juego, victoria,
/// derrota) se agregan en Sprint 2.
class ArrowMazeApp extends StatelessWidget {
  /// Crea el widget raíz de la aplicación.
  const ArrowMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow-Maze Escape',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Arrow-Maze Escape Puzzle'),
        ),
      ),
    );
  }
}
