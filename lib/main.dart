import 'package:flutter/material.dart';

/// Punto de entrada de la aplicación móvil Arrow-Maze.
/// La UI se implementará en la capa de Arquitectura; el dominio ya está listo.
void main() {
  runApp(const ArrowMazeApp());
}

class ArrowMazeApp extends StatelessWidget {
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
