import 'dart:math';

import '../board/value_objects/face.dart';
import '../shared/enums/arrow_direction.dart';
import '../shared/exceptions/domain_exception.dart';
import '../shared/value_objects/direction.dart';
import '../shared/value_objects/identifier.dart';
import 'cube_escape_point.dart';
import 'cube_path_arrow.dart';
import 'cube_surface_board.dart';
import 'cube_surface_position.dart';
import 'cube_surface_topology.dart';

/// Nivel generado junto con un orden de solución comprobado.
class GeneratedCubeSurfaceLevel {
  /// Crea un nivel generado.
  const GeneratedCubeSurfaceLevel({
    required this.board,
    required this.solutionOrder,
  });

  /// Estado inicial del tablero.
  final CubeSurfaceBoard board;

  /// IDs en un orden que siempre limpia el tablero.
  final List<Identifier> solutionOrder;
}

/// Genera flechas y escape aleatorios sobre las seis caras.
///
/// Cada flecha tiene cuerpo de [minBodyLength]–[maxBodyLength] celdas detrás
/// de la punta (puede cruzar aristas hacia otras caras). La garantía de
/// solución se obtiene construyendo un orden de eliminación que respeta
/// tip+body ocupados.
class CubeSurfaceLevelGenerator {
  /// Crea el generador.
  const CubeSurfaceLevelGenerator({
    this.faceSize = 3,
    this.arrowCount = 6,
    this.minBodyLength = 1,
    this.maxBodyLength = 4,
    this.maxAttempts = 1200,
  });

  /// Tamaño NxN de cada cara.
  final int faceSize;

  /// Cantidad de flechas del nivel.
  final int arrowCount;

  /// Longitud mínima del cuerpo (celdas detrás de la punta).
  final int minBodyLength;

  /// Longitud máxima del cuerpo (celdas detrás de la punta).
  final int maxBodyLength;

  /// Intentos máximos antes de declarar que la configuración es inviable.
  final int maxAttempts;

  /// Genera un nivel. [seed] permite reproducirlo en pruebas.
  GeneratedCubeSurfaceLevel generate({int? seed}) {
    if (minBodyLength < 1 || maxBodyLength < minBodyLength) {
      throw DomainException(
        'CubeSurfaceLevelGenerator body length must satisfy 1 <= min <= max.',
      );
    }
    final random = Random(seed);
    final topology = CubeSurfaceTopology(faceSize);
    final all = topology.positions;
    if (arrowCount < 1 || arrowCount >= all.length) {
      throw DomainException(
        'CubeSurfaceLevelGenerator arrowCount must be between 1 and ${all.length - 1}.',
      );
    }

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final shuffled = List<CubeSurfacePosition>.from(all)..shuffle(random);
      final escape = shuffled.removeLast();
      final directed = <_TipCandidate>[];
      for (final position in shuffled) {
        for (final arrowDirection in ArrowDirection.values) {
          final direction = Direction(arrowDirection);
          final route = topology.traceTo(
            start: position,
            direction: direction,
            goal: escape,
          );
          if (route != null) {
            directed.add((
              tip: position,
              direction: direction,
              route: route,
            ));
          }
        }
      }
      directed.shuffle(random);

      final tipPicks = <_TipCandidate>[];
      final usedTips = <CubeSurfacePosition>{};

      // Evita caras visualmente vacías: al menos una punta en cada cara.
      for (final face in Face.values) {
        final faceCandidates = directed.where(
          (candidate) =>
              candidate.tip.face == face && !usedTips.contains(candidate.tip),
        );
        if (faceCandidates.isEmpty || tipPicks.length == arrowCount) break;
        final selected = faceCandidates.first;
        tipPicks.add(selected);
        usedTips.add(selected.tip);
      }
      if (tipPicks.length < Face.values.length &&
          arrowCount >= Face.values.length) {
        continue;
      }
      for (final candidate in directed) {
        if (tipPicks.length == arrowCount) break;
        if (usedTips.add(candidate.tip)) tipPicks.add(candidate);
      }
      if (tipPicks.length != arrowCount) continue;

      final withBodies = _assignBodies(
        topology: topology,
        tips: tipPicks,
        escape: escape,
        random: random,
      );
      if (withBodies == null) continue;

      final level = _tryBuild(escape: escape, starts: withBodies, random: random);
      if (level != null) return level;
    }

    throw DomainException(
      'Could not generate a solvable cube surface level after $maxAttempts attempts.',
    );
  }

  /// Extiende cada punta hacia atrás (opuesto a la dirección del tip) 1–4 celdas.
  List<_ArrowCandidate>? _assignBodies({
    required CubeSurfaceTopology topology,
    required List<_TipCandidate> tips,
    required CubeSurfacePosition escape,
    required Random random,
  }) {
    final tipCells = {for (final tip in tips) tip.tip};
    final routeCells = {
      for (final tip in tips) ...tip.route,
    };
    final hardOccupied = <CubeSurfacePosition>{escape, ...tipCells};
    final softOccupied = <CubeSurfacePosition>{
      ...hardOccupied,
      ...routeCells,
    };
    final order = List<_TipCandidate>.from(tips)..shuffle(random);
    final bodiesByTip = <CubeSurfacePosition, List<CubeSurfacePosition>>{};

    for (final tip in order) {
      final lengths = [
        for (var length = minBodyLength; length <= maxBodyLength; length++)
          length,
      ]..shuffle(random);
      if (random.nextDouble() < 0.65) {
        lengths.sort();
      }

      List<CubeSurfacePosition>? chosen;
      // 1) Preferir cuerpo fuera de rutas de escape (conserva solvabilidad).
      for (final length in lengths) {
        final body = _bodyBehindTip(
          topology: topology,
          tip: tip.tip,
          tipDirection: tip.direction,
          length: length,
          forbidden: softOccupied,
        );
        if (body != null) {
          chosen = body;
          break;
        }
      }
      // 2) Si no cabe, permitir solapar rutas y revalidar después.
      chosen ??= () {
        for (final length in lengths) {
          final body = _bodyBehindTip(
            topology: topology,
            tip: tip.tip,
            tipDirection: tip.direction,
            length: length,
            forbidden: hardOccupied,
          );
          if (body != null) return body;
        }
        return null;
      }();

      if (chosen == null) return null;
      bodiesByTip[tip.tip] = chosen;
      hardOccupied.addAll(chosen);
      softOccupied.addAll(chosen);
    }

    return [
      for (final tip in tips)
        (
          tip: tip.tip,
          direction: tip.direction,
          route: tip.route,
          body: bodiesByTip[tip.tip]!,
        ),
    ];
  }

  /// Celdas del cuerpo caminando en sentido contrario al tip; puede cruzar caras.
  List<CubeSurfacePosition>? _bodyBehindTip({
    required CubeSurfaceTopology topology,
    required CubeSurfacePosition tip,
    required Direction tipDirection,
    required int length,
    required Set<CubeSurfacePosition> forbidden,
  }) {
    final body = <CubeSurfacePosition>[];
    var current = tip;
    var walkDirection = tipDirection.opposite;

    for (var i = 0; i < length; i++) {
      final step = topology.stepForward(current, walkDirection);
      final next = step.position;
      if (forbidden.contains(next) || next == tip || body.contains(next)) {
        return null;
      }
      body.add(next);
      current = next;
      walkDirection = step.direction;
    }
    return body;
  }

  GeneratedCubeSurfaceLevel? _tryBuild({
    required CubeSurfacePosition escape,
    required List<_ArrowCandidate> starts,
    required Random random,
  }) {
    final remaining = <Identifier, _ArrowCandidate>{
      for (var i = 0; i < starts.length; i++)
        Identifier('arrow-${i + 1}'): starts[i],
    };
    final arrows = <Identifier, CubePathArrow>{};
    final order = <Identifier>[];

    while (remaining.isNotEmpty) {
      final candidates = <({Identifier id, List<CubeSurfacePosition> path})>[];

      for (final entry in remaining.entries) {
        final blocked = <CubeSurfacePosition>{
          for (final other in remaining.entries)
            if (other.key != entry.key) ...[
              other.value.tip,
              ...other.value.body,
            ],
        };
        if (!entry.value.route.any(blocked.contains)) {
          candidates.add((id: entry.key, path: entry.value.route));
        }
      }

      if (candidates.isEmpty) return null;
      final selected = candidates[random.nextInt(candidates.length)];
      final candidate = remaining.remove(selected.id)!;
      arrows[selected.id] = CubePathArrow(
        id: selected.id,
        tip: candidate.tip,
        direction: candidate.direction,
        body: candidate.body,
        escapeRoute: candidate.route,
      );
      order.add(selected.id);
    }

    return GeneratedCubeSurfaceLevel(
      board: CubeSurfaceBoard(
        faceSize: faceSize,
        escapePoint: CubeEscapePoint(escape),
        arrows: starts.indexed
            .map((entry) => arrows[Identifier('arrow-${entry.$1 + 1}')]!)
            .toList(growable: false),
      ),
      solutionOrder: List.unmodifiable(order),
    );
  }
}

typedef _TipCandidate = ({
  CubeSurfacePosition tip,
  Direction direction,
  List<CubeSurfacePosition> route,
});

typedef _ArrowCandidate = ({
  CubeSurfacePosition tip,
  Direction direction,
  List<CubeSurfacePosition> route,
  List<CubeSurfacePosition> body,
});
