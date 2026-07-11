import 'package:flutter/material.dart';

/// Paleta visual del juego inspirada en Tollens (minimalista) y el logo del laberinto.
///
/// Centraliza los colores para que tablero, flechas y pantallas mantengan
/// coherencia sin depender del `ColorScheme` genérico de Material.
abstract final class AppColors {
  /// Fondo general de pantallas (CR4001-1 — blanco crema).
  static const background = Color(0xFFF5F3EF);

  /// Superficie del contenedor del tablero (CR4012-3 — greige).
  static const boardSurface = Color(0xFFE8E4DE);

  /// Líneas de rejilla y bordes suaves (CR4043-1).
  static const gridLine = Color(0xFF9E9E9E);

  /// Trazo principal de flechas activas (CR4206-1 — slate).
  static const arrow = Color(0xFF455A64);

  /// Celdas de muro (CR4206-6 — carbón).
  static const wall = Color(0xFF263238);

  /// Flecha bloqueada (acento rosa del logo).
  static const arrowBlocked = Color(0xFFF06292);

  /// Flecha seleccionada o en foco (acento azul del logo).
  static const arrowActive = Color(0xFF42A5F5);

  /// Éxito: niveles completados, victoria (acento verde del logo).
  static const success = Color(0xFF8BC34A);

  /// Acento arena para contenedores secundarios (CR4048-3).
  static const sand = Color(0xFFC4B8A8);

  /// Texto principal sobre fondos claros.
  static const textPrimary = Color(0xFF263238);
}
