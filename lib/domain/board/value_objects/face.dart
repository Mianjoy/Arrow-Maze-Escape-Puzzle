/// Cara del cubo.
///
/// En [CubeBoard] (6 tableros independientes) cada flecha vive en una sola cara.
/// En [CubeSurfaceBoard] (Modo 3D) punta y cuerpo sí pueden pertenecer a caras
/// distintas y salir por un [CubeEscapePoint].
enum Face {
  /// Cara superior.
  top,

  /// Cara inferior.
  bottom,

  /// Cara frontal.
  front,

  /// Cara trasera.
  back,

  /// Cara izquierda.
  left,

  /// Cara derecha.
  right,
}
