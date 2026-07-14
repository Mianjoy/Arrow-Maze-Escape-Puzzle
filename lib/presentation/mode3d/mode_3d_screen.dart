import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'mode_3d_catalog.dart';
import 'mode_3d_solution_map.dart';
import 'mode_3d_victory_overlay.dart';

/// Modo 3D táctil: rotar con drag, tocar flecha libre para que salga.
class Mode3DScreen extends StatefulWidget {
  /// Crea la pantalla del modo 3D.
  const Mode3DScreen({super.key});

  @override
  State<Mode3DScreen> createState() => _Mode3DScreenState();
}

class _Mode3DScreenState extends State<Mode3DScreen> {
  static const int n = kMode3dFaceSize;
  static const double cellSize = 1.0;
  static const double cellGap = 0.12;
  static const double step = cellSize + cellGap;
  static const double faceExtent = n * step;
  static const double coreSize = faceExtent - cellGap;
  static const double halfExtent = coreSize / 2 + 0.08;
  static const double _tapRadiusPx = 72;

  static const _bgColor = 0x2a2f36;
  static const _coreColor = 0x1b1f24;
  static const _escapeColor = 0xffc107;
  static const _arrowColor = 0x0a0a0a;
  /// Celda libre (disparable): contraste fuerte con la flecha negra.
  static const _freeGlow = 0xd7dce2;
  /// Punta ocupada pero bloqueada.
  static const _blockedTipGlow = 0x8a9098;
  /// Segmento de cuerpo (1–4 celdas, puede estar en otra cara).
  static const _bodySegmentColor = 0x1a1a1a;
  static const _bodyCellGlow = 0x9aa1a8;

  three.ThreeJS? threeJs;
  final _engine = const CubePathMovementEngine();
  final _raycaster = three.Raycaster();
  final _pointerNdc = three.Vector2(0, 0);
  final _cameraTarget = three.Vector3(0, 0, 0);

  late GeneratedCubeSurfaceLevel _level;
  late CubeSurfaceBoard _board;

  /// Celdas-punta usadas para raycast (nunca se quitan de la escena).
  final Map<three.Object3D, CubeSurfacePosition> _pickables = {};
  final Map<CubeSurfacePosition, three.Mesh> _cellMeshes = {};
  final Map<Face, three.Group> _faceGroups = {};
  final Map<Face, three.Group> _arrowGroupByFace = {};

  String? _statusText;
  bool _busy = false;
  bool _showVictory = false;
  bool _sceneReady = false;
  Size? _viewSize;
  double _orbitYaw = 0.65;
  double _orbitPitch = 0.55;
  double _orbitDistance = faceExtent * 3.1;

  /// Tap vs drag: ScaleGestureRecognizer se come onTapUp si no se gestiona así.
  Offset? _gestureLocal;
  bool _gestureMoved = false;

  @override
  void initState() {
    super.initState();
    _level = buildRandomMode3dLevel();
    _board = _level.board;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _statusText ??= AppStringsScope.of(context).mode3dStatusHint;
  }

  @override
  void dispose() {
    threeJs?.dispose();
    three.loading.clear();
    super.dispose();
  }

  void _ensureThreeJs(Size size) {
    if (threeJs != null || size.width < 8 || size.height < 8) return;
    _viewSize = size;
    threeJs = three.ThreeJS(
      size: size,
      onSetupComplete: () {
        if (mounted) setState(() {});
      },
      setup: _setup,
    );
  }

  Future<void> _setup() async {
    final js = threeJs!;
    js.camera = three.PerspectiveCamera(46, js.width / js.height, 0.1, 100);
    _applyOrbitCamera();

    js.scene = three.Scene();
    js.scene.background = three.Color.fromHex32(_bgColor);
    js.scene.add(three.AmbientLight(0xffffff, 0.85));
    final keyLight = three.DirectionalLight(0xffffff, 0.4);
    keyLight.position.setValues(faceExtent, faceExtent * 1.8, faceExtent);
    js.scene.add(keyLight);

    final core = three.Mesh(
      three.BoxGeometry(coreSize, coreSize, coreSize),
      three.MeshBasicMaterial.fromMap({'color': _coreColor}),
    );
    js.scene.add(core);

    for (final face in Face.values) {
      _buildFace(face);
    }
    // Debe quedar listo antes de pintar flechas/colores (si no, el early
    // return de _rebuildArrows/_refreshCellColors deja el cubo vacío).
    _sceneReady = true;
    _rebuildArrows();
    _refreshCellColors();
    js.scene.updateMatrixWorld(true);

    // Sin OrbitControls: el canvas (HtmlElementView) no recibe toques;
    // Flutter maneja tap y drag encima.
    if (mounted) setState(() {});
  }

  void _applyOrbitCamera() {
    final js = threeJs;
    if (js == null) return;
    final pitch = _orbitPitch.clamp(0.18, math.pi - 0.18);
    _orbitPitch = pitch;
    final x = _orbitDistance * math.sin(pitch) * math.sin(_orbitYaw);
    final y = _orbitDistance * math.cos(pitch);
    final z = _orbitDistance * math.sin(pitch) * math.cos(_orbitYaw);
    js.camera.position.setValues(x, y, z);
    js.camera.lookAt(_cameraTarget);
    js.camera.updateMatrixWorld(true);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureLocal = details.localFocalPoint;
    _gestureMoved = false;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_busy || _showVictory) return;
    final isPinch =
        details.pointerCount >= 2 || (details.scale - 1.0).abs() > 0.015;
    final dragDistance = details.focalPointDelta.distance;
    if (isPinch || dragDistance > 2.5) {
      _gestureMoved = true;
    }
    if (!_gestureMoved && !isPinch) return;

    setState(() {
      if (isPinch) {
        _orbitDistance =
            (_orbitDistance / details.scale).clamp(faceExtent * 1.4, faceExtent * 7.0);
      } else {
        _orbitYaw -= details.focalPointDelta.dx * 0.01;
        _orbitPitch -= details.focalPointDelta.dy * 0.01;
      }
      _applyOrbitCamera();
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final local = _gestureLocal;
    final wasTap = !_gestureMoved && local != null;
    _gestureLocal = null;
    _gestureMoved = false;
    if (wasTap) _handleTapAt(local);
  }

  (three.Vector3 position, three.Vector3 rotationRad) _faceTransform(Face face) {
    double d(double deg) => three.MathUtils.degToRad(deg);
    return switch (face) {
      Face.front => (three.Vector3(0, 0, halfExtent), three.Vector3(0, 0, 0)),
      Face.back => (three.Vector3(0, 0, -halfExtent), three.Vector3(0, d(180), 0)),
      Face.right => (three.Vector3(halfExtent, 0, 0), three.Vector3(0, d(-90), 0)),
      Face.left => (three.Vector3(-halfExtent, 0, 0), three.Vector3(0, d(90), 0)),
      Face.top => (three.Vector3(0, halfExtent, 0), three.Vector3(d(-90), 0, 0)),
      Face.bottom => (three.Vector3(0, -halfExtent, 0), three.Vector3(d(90), 0, 0)),
    };
  }

  int _cellColor(Face face) => switch (face) {
        Face.front => 0x9aa0a6,
        Face.back => 0x7e848b,
        Face.left => 0x8f959c,
        Face.right => 0x747a81,
        Face.top => 0xb0b5ba,
        Face.bottom => 0x636970,
      };

  void _buildFace(Face face) {
    final js = threeJs!;
    final (position, rotation) = _faceTransform(face);
    final faceGroup = three.Group();
    faceGroup.position.setValues(position.x, position.y, position.z);
    faceGroup.rotation.x = rotation.x;
    faceGroup.rotation.y = rotation.y;
    faceGroup.rotation.z = rotation.z;

    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final cellPos = CubeSurfacePosition(face: face, row: row, column: col);
        final cell = three.Mesh(
          three.BoxGeometry(cellSize * 0.88, cellSize * 0.88, 0.14),
          three.MeshBasicMaterial.fromMap({'color': _cellColor(face)}),
        );
        final (lx, ly) = _cellLocal(face, row, col);
        cell.position.setValues(lx, ly, 0.02);
        faceGroup.add(cell);
        _cellMeshes[cellPos] = cell;
      }
    }

    final arrowGroup = three.Group();
    faceGroup.add(arrowGroup);
    _faceGroups[face] = faceGroup;
    _arrowGroupByFace[face] = arrowGroup;
    js.scene.add(faceGroup);
  }

  double _localX(int col) => (col - (n - 1) / 2) * step;
  /// Fila 0 arriba (+Y local), fila máxima abajo (-Y), igual que la topología.
  double _localY(int row) => ((n - 1) / 2 - row) * step;

  /// XY local alineado con el wrap 3D (left/right invierten columnas).
  (double, double) _cellLocal(Face face, int row, int column) {
    final max = n - 1;
    final x = switch (face) {
      Face.left || Face.right => _localX(max - column),
      _ => _localX(column),
    };
    return (x, _localY(row));
  }

  bool _isFree(CubePathArrow arrow) {
    return _engine.attemptFire(board: _board, arrowId: arrow.id).result.isExtracted;
  }

  void _refreshCellColors() {
    if (!_sceneReady) return;
    for (final entry in _cellMeshes.entries) {
      final pos = entry.key;
      final mesh = entry.value;
      final arrow = _board.arrowAt(pos);
      final int color;
      if (pos == _board.escapePoint.position) {
        color = _escapeColor;
      } else if (arrow != null && arrow.tip == pos) {
        color = _isFree(arrow) ? _freeGlow : _blockedTipGlow;
      } else if (arrow != null) {
        // Cuerpo: un poco más oscuro que la cara; libre se nota en la punta.
        color = _isFree(arrow) ? _freeGlow : _bodyCellGlow;
      } else {
        color = _cellColor(pos.face);
      }
      mesh.material = three.MeshBasicMaterial.fromMap({'color': color});
    }
  }

  three.Vector3 _cellWorld(CubeSurfacePosition p, {double lift = 0.22}) {
    final (origin, rot) = _faceTransform(p.face);
    final (lx, ly) = _cellLocal(p.face, p.row, p.column);
    final local = three.Vector3(lx, ly, lift);
    local.applyEuler(three.Euler(rot.x, rot.y, rot.z));
    return three.Vector3(origin.x + local.x, origin.y + local.y, origin.z + local.z);
  }

  Future<void> _animateEscape(CubePathArrow arrow) async {
    final js = threeJs;
    if (!_sceneReady || js == null) return;
    final path = <CubeSurfacePosition>[arrow.tip, ...arrow.escapeRoute];
    if (path.length < 2) return;

    final flyer = three.Group();
    final arrowVisual = _createArrowVisual(_arrowColor);
    flyer.add(arrowVisual);
    _placeFlyingArrow(flyer, arrowVisual, path.first, path[1]);
    js.scene.add(flyer);

    const steps = 16;
    for (var i = 1; i <= steps; i++) {
      if (!mounted) break;
      final t = i / steps;
      final along = t * (path.length - 1);
      final i0 = along.floor().clamp(0, path.length - 2);
      final frac = along - i0;
      final a = _cellWorld(path[i0]);
      final b = _cellWorld(path[i0 + 1]);
      _orientFlyingArrow(flyer, arrowVisual, path[i0], path[i0 + 1]);
      var x = a.x + (b.x - a.x) * frac;
      var y = a.y + (b.y - a.y) * frac;
      var z = a.z + (b.z - a.z) * frac;
      if (path[i0].face != path[i0 + 1].face) {
        final maxAxis = math.max(x.abs(), math.max(y.abs(), z.abs()));
        if (maxAxis > 0.0001) {
          final scale = (halfExtent + 0.2) / maxAxis;
          x *= scale;
          y *= scale;
          z *= scale;
        }
      }
      flyer.position.setValues(x, y, z);
      final s = 1.0 - t * 0.55;
      flyer.scale.setValues(s, s, s);
      await Future<void>.delayed(const Duration(milliseconds: 18));
    }
    js.scene.remove(flyer);
  }

  void _rebuildArrows() {
    if (!_sceneReady) return;

    // Solo limpia el mapa: las celdas siguen en la escena.
    _pickables.clear();

    for (final group in _arrowGroupByFace.values) {
      final toRemove = List<three.Object3D>.from(group.children);
      for (final child in toRemove) {
        group.remove(child);
      }
    }

    final topology = CubeSurfaceTopology(n);

    for (final arrow in _board.arrows) {
      final tip = arrow.tip;
      final tipGroup = _arrowGroupByFace[tip.face];
      if (tipGroup == null) continue;

      final visual = _createArrowVisual(_arrowColor);
      final (tx, ty) = _cellLocal(tip.face, tip.row, tip.column);
      visual.position.setValues(tx, ty, 0.16);
      visual.rotation.z = _tipAngleOnFace(tip.face, arrow.direction.arrowDirection);
      visual.renderOrder = 3;
      tipGroup.add(visual);

      for (final cell in arrow.occupiedCells) {
        final mesh = _cellMeshes[cell];
        if (mesh != null) _pickables[mesh] = cell;
      }

      // Segmentos de cuerpo: barra plana orientada hacia la punta.
      final shaft = <CubeSurfacePosition>[tip, ...arrow.body];
      for (var i = 1; i < shaft.length; i++) {
        final cell = shaft[i];
        final towardTip = shaft[i - 1];
        final faceGroup = _arrowGroupByFace[cell.face];
        if (faceGroup == null) continue;

        final segment = _createBodySegment(_bodySegmentColor);
        final (cx, cy) = _cellLocal(cell.face, cell.row, cell.column);
        segment.position.setValues(cx, cy, 0.14);
        final along = topology.directionBetween(cell, towardTip);
        // En left/right las columnas están espejadas: left/right visuales
        // intercambian el sentido local de la barra.
        segment.rotation.z = _bodyAngleOnFace(cell.face, along.arrowDirection);
        segment.renderOrder = 2;
        faceGroup.add(segment);
      }
    }

    threeJs?.scene.updateMatrixWorld(true);
  }

  /// Segmento de cuerpo plano (rectángulo) alineado con el eje de la flecha.
  three.Mesh _createBodySegment(int color) {
    return three.Mesh(
      three.BoxGeometry(cellSize * 0.34, cellSize * 0.72, 0.035),
      three.MeshBasicMaterial.fromMap({
        'color': color,
        'side': three.DoubleSide,
        'depthTest': false,
        'depthWrite': false,
      }),
    );
  }

  /// Ángulo de silueta: left/right espejan X, así left↔right en pantalla.
  double _bodyAngleOnFace(Face face, ArrowDirection direction) {
    final visual = switch (face) {
      Face.left || Face.right => switch (direction) {
          ArrowDirection.left => ArrowDirection.right,
          ArrowDirection.right => ArrowDirection.left,
          _ => direction,
        },
      _ => direction,
    };
    return _directionAngle(visual);
  }

  /// Ángulo de punta (misma corrección de espejo que el cuerpo).
  double _tipAngleOnFace(Face face, ArrowDirection direction) =>
      _bodyAngleOnFace(face, direction);

  /// Flecha plana (grosor mínimo en Z). No usa ShapeGeometry: en three_js web
  /// a menudo no se rasteriza y dejan celdas “libres” en blanco sin silueta.
  three.Group _createArrowVisual(int color) {
    final material = three.MeshBasicMaterial.fromMap({
      'color': color,
      'side': three.DoubleSide,
      // Por encima de la celda sin pelear profundidad.
      'depthTest': false,
      'depthWrite': false,
    });
    final group = three.Group();
    const thickness = 0.035;

    final shaft = three.Mesh(
      three.BoxGeometry(0.20, 0.40, thickness),
      material,
    );
    shaft.position.setValues(0, -0.08, 0);
    group.add(shaft);

    // Cabeza en “V” plana (dos barras finas), no un cono 3D.
    final leftArm = three.Mesh(
      three.BoxGeometry(0.32, 0.11, thickness),
      material,
    );
    leftArm.position.setValues(-0.11, 0.22, 0);
    leftArm.rotation.z = 0.60;
    group.add(leftArm);

    final rightArm = three.Mesh(
      three.BoxGeometry(0.32, 0.11, thickness),
      material,
    );
    rightArm.position.setValues(0.11, 0.22, 0);
    rightArm.rotation.z = -0.60;
    group.add(rightArm);

    return group;
  }

  double _directionAngle(ArrowDirection direction) => switch (direction) {
        ArrowDirection.up => 0,
        ArrowDirection.right => -three.MathUtils.degToRad(90),
        ArrowDirection.down => three.MathUtils.degToRad(180),
        ArrowDirection.left => three.MathUtils.degToRad(90),
      };

  void _placeFlyingArrow(
    three.Group group,
    three.Object3D mesh,
    CubeSurfacePosition position,
    CubeSurfacePosition next,
  ) {
    group.position.setFrom(_cellWorld(position));
    _orientFlyingArrow(group, mesh, position, next);
  }

  void _orientFlyingArrow(
    three.Group group,
    three.Object3D mesh,
    CubeSurfacePosition position,
    CubeSurfacePosition next,
  ) {
    final (_, rotation) = _faceTransform(position.face);
    group.rotation.set(rotation.x, rotation.y, rotation.z);
    final direction = CubeSurfaceTopology(n).directionBetween(position, next);
    mesh.rotation.z = _directionAngle(direction.arrowDirection);
  }

  CubeSurfacePosition? _pickWithRay(Offset local) {
    final js = threeJs;
    final size = _viewSize;
    if (js == null || size == null || size.width <= 0 || size.height <= 0) {
      return null;
    }

    _pointerNdc.x = (local.dx / size.width) * 2 - 1;
    _pointerNdc.y = -(local.dy / size.height) * 2 + 1;

    js.camera.updateMatrixWorld(true);
    js.scene.updateMatrixWorld(true);
    _raycaster.setFromCamera(_pointerNdc, js.camera);

    final targets = _pickables.keys.toList(growable: false);
    if (targets.isEmpty) return null;
    final hits = _raycaster.intersectObjects(targets, false);
    if (hits.isEmpty) return null;
    return _pickables[hits.first.object];
  }

  CubeSurfacePosition? _pickByScreenProximity(Offset local) {
    final js = threeJs;
    final size = _viewSize;
    if (js == null || size == null) return null;

    js.camera.updateMatrixWorld(true);
    CubeSurfacePosition? closest;
    var best = _tapRadiusPx * _tapRadiusPx;

    for (final arrow in _board.arrows) {
      for (final cell in arrow.occupiedCells) {
        final world = _cellWorld(cell);
        final projected = world.clone()..project(js.camera);
        // Solo descartar lo claramente detrás de la cámara.
        if (projected.z > 1.05) continue;
        final screenX = (projected.x + 1) * 0.5 * size.width;
        final screenY = (1 - projected.y) * 0.5 * size.height;
        final dx = screenX - local.dx;
        final dy = screenY - local.dy;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared <= best) {
          best = distanceSquared;
          closest = cell;
        }
      }
    }
    return closest;
  }

  CubeSurfacePosition? _resolveTap(Offset local) {
    // Proximidad primero: fiable con la capa Flutter encima del canvas.
    final near = _pickByScreenProximity(local);
    if (near != null) return near;
    final rayHit = _pickWithRay(local);
    if (rayHit != null && _board.arrowAt(rayHit) != null) return rayHit;
    return null;
  }

  void _handleTapAt(Offset local) {
    if (_busy || _showVictory || !_sceneReady) return;
    final pos = _resolveTap(local);
    if (pos == null) {
      setState(() {
        _statusText = AppStringsScope.of(context).mode3dStatusHint;
      });
      return;
    }
    unawaited(_fireAt(pos));
  }

  Future<void> _fireAt(CubeSurfacePosition position) async {
    if (_busy || _showVictory) return;

    final tappedArrow = _board.arrowAt(position);
    final preview = _engine.attemptFireAt(board: _board, position: position);

    if (tappedArrow == null || !preview.result.isExtracted) {
      if (!mounted) return;
      setState(() {
        _statusText = _describeOutcome(preview.result, position);
      });
      return;
    }

    _busy = true;
    try {
      // Animar primero; luego mutar tablero (la flecha ya se ve salir).
      await _animateEscape(tappedArrow);
      if (!mounted) return;
      setState(() {
        _board = preview.board;
        _rebuildArrows();
        _refreshCellColors();
        _statusText = _describeOutcome(preview.result, position);
        if (_board.isCleared) {
          _showVictory = true;
          _statusText = AppStringsScope.of(context).mode3dVictoryTitle;
        }
      });
    } finally {
      _busy = false;
    }
  }

  String _describeOutcome(MoveResult result, CubeSurfacePosition tapped) {
    final strings = AppStringsScope.of(context);
    final faceLabel = tapped.face.name.toUpperCase();
    if (result.isNoArrowAtCell) return strings.mode3dNoArrow(faceLabel);
    if (result.isBlocked) return strings.mode3dBlocked(faceLabel);
    if (result.isExtracted) {
      return _board.isCleared
          ? strings.mode3dCubeSolved(faceLabel)
          : strings.mode3dExtracted(faceLabel);
    }
    return strings.mode3dInvalid(faceLabel);
  }

  void _retry() {
    setState(() {
      _level = buildRandomMode3dLevel();
      _board = _level.board;
      _showVictory = false;
      _busy = false;
      _statusText = AppStringsScope.of(context).mode3dStatusHint;
      if (_sceneReady) {
        _rebuildArrows();
        _refreshCellColors();
      }
    });
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF2A2F36),
      appBar: AppBar(
        title: Text(strings.mode3dTitle),
        backgroundColor: AppColors.boardSurface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            tooltip: strings.mode3dRetry,
            onPressed: _busy ? null : _retry,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            key: const ValueKey('mode3d-solution-map'),
            tooltip: strings.mode3dSolutionMapTitle,
            onPressed: () => showMode3dSolutionMap(
              context,
              board: _board,
              solutionOrder: _level.solutionOrder,
            ),
            icon: const Icon(Icons.playlist_add_check),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                _viewSize = size;
                _ensureThreeJs(size);
                final js = threeJs;
                if (js == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Capas: canvas sin eventos + capa Flutter que recibe toques.
                return Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(child: js.build()),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onScaleEnd: _onScaleEnd,
                        child: const ColoredBox(color: Color(0x01000000)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 10,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.boardSurface.withValues(alpha: 0.93),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sand),
                ),
                child: Text(
                  _statusText ?? strings.mode3dStatusHint,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (_showVictory)
            Positioned.fill(
              child: Mode3dVictoryOverlay(onRetry: _retry, onHome: _goHome),
            ),
        ],
      ),
    );
  }
}
