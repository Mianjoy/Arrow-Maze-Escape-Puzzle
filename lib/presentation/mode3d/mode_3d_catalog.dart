import '../../domain/domain.dart';

/// Tamaño de cara del Modo 3D de prueba (sencillo de orbitar y tocar).
const int kMode3dFaceSize = 3;

/// Identificadores estables del nivel demo 3×3.
const String kMode3dDemoLevelId = 'cube-surface-demo-3x3';

/// Generador del nivel jugable: ocho flechas distribuidas en las seis caras.
const CubeSurfaceLevelGenerator kMode3dLevelGenerator =
    CubeSurfaceLevelGenerator(faceSize: kMode3dFaceSize, arrowCount: 6);

/// Construye un mapa aleatorio con escape y orden de solución garantizado.
GeneratedCubeSurfaceLevel buildRandomMode3dLevel({int? seed}) =>
    kMode3dLevelGenerator.generate(seed: seed);

/// Construye el tablero de superficie 3×3 con flechas multi-cara y escape fijo.
///
/// Escape: TOP (0, 1) — celda verde.
/// Orden: `blocker` → `bridge` → `corner`.
/// `bridge` tiene punta en FRONT y cuerpo en TOP (caras distintas).
CubeSurfaceBoard buildMode3dDemoBoard() {
  final escape = const CubeSurfacePosition(face: Face.top, row: 0, column: 1);

  final blocker = CubePathArrow(
    id: const Identifier('blocker'),
    tip: const CubeSurfacePosition(face: Face.front, row: 0, column: 1),
    direction: const Direction(ArrowDirection.up),
    body: const [
      CubeSurfacePosition(face: Face.front, row: 0, column: 2),
    ],
    // Ruta al escape por la columna 2 de TOP, sin pasar por el cuerpo de bridge.
    escapeRoute: const [
      CubeSurfacePosition(face: Face.top, row: 2, column: 2),
      CubeSurfacePosition(face: Face.top, row: 1, column: 2),
      CubeSurfacePosition(face: Face.top, row: 0, column: 2),
      CubeSurfacePosition(face: Face.top, row: 0, column: 1),
    ],
  );

  final bridge = CubePathArrow(
    id: const Identifier('bridge'),
    tip: const CubeSurfacePosition(face: Face.front, row: 1, column: 1),
    direction: const Direction(ArrowDirection.up),
    body: const [
      // Cuerpo en otra cara distinta a la punta.
      CubeSurfacePosition(face: Face.top, row: 2, column: 1),
    ],
    escapeRoute: const [
      CubeSurfacePosition(face: Face.front, row: 0, column: 1),
      CubeSurfacePosition(face: Face.top, row: 2, column: 1),
      CubeSurfacePosition(face: Face.top, row: 1, column: 1),
      CubeSurfacePosition(face: Face.top, row: 0, column: 1),
    ],
  );

  final corner = CubePathArrow(
    id: const Identifier('corner'),
    tip: const CubeSurfacePosition(face: Face.right, row: 1, column: 0),
    direction: const Direction(ArrowDirection.left),
    body: const [
      CubeSurfacePosition(face: Face.front, row: 1, column: 2),
    ],
    escapeRoute: const [
      CubeSurfacePosition(face: Face.front, row: 1, column: 1),
      CubeSurfacePosition(face: Face.front, row: 0, column: 1),
      CubeSurfacePosition(face: Face.top, row: 2, column: 1),
      CubeSurfacePosition(face: Face.top, row: 1, column: 1),
      CubeSurfacePosition(face: Face.top, row: 0, column: 1),
    ],
  );

  return CubeSurfaceBoard(
    faceSize: kMode3dFaceSize,
    escapePoint: CubeEscapePoint(escape),
    arrows: [blocker, bridge, corner],
  );
}

/// Orden sugerido de disparo para el mapa de solución.
const List<String> kMode3dDemoSolutionOrder = [
  'blocker',
  'bridge',
  'corner',
];
