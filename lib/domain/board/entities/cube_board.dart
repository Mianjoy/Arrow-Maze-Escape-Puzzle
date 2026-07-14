import 'package:meta/meta.dart';

import '../../shared/exceptions/domain_exception.dart';
import '../value_objects/face.dart';
import 'board.dart';

/// Agregado raíz de un cubo jugable: 6 [Board] independientes, uno por cara.
///
/// No hay interacción entre caras — cada una resuelve su propia partida con
/// el motor de reglas existente ([ArrowMovementEngine]/[CollisionValidator])
/// sin modificaciones. Inmutable como [Board]: actualizar una cara produce
/// una copia nueva vía [withUpdatedFace].
@immutable
class CubeBoard {
  /// Crea el cubo a partir de un tablero por cada una de las 6 caras.
  CubeBoard({required Map<Face, Board> boardsByFace})
      : _boardsByFace = Map.unmodifiable(boardsByFace) {
    _ensureAllFacesPresent();
  }

  final Map<Face, Board> _boardsByFace;

  /// Devuelve el tablero jugable de [face].
  Board boardAt(Face face) {
    final board = _boardsByFace[face];
    if (board == null) {
      throw DomainException('CubeBoard is missing face $face.');
    }
    return board;
  }

  /// El cubo está resuelto cuando las 6 caras lo están (sin flechas restantes).
  bool get isCleared => Face.values.every((face) => boardAt(face).isCleared);

  /// Retorna una copia de este cubo con la cara [face] reemplazada por [updatedBoard].
  CubeBoard withUpdatedFace(Face face, Board updatedBoard) {
    final updated = Map<Face, Board>.from(_boardsByFace);
    updated[face] = updatedBoard;
    return CubeBoard(boardsByFace: updated);
  }

  void _ensureAllFacesPresent() {
    for (final face in Face.values) {
      if (!_boardsByFace.containsKey(face)) {
        throw DomainException('CubeBoard is missing face $face.');
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CubeBoard &&
          runtimeType == other.runtimeType &&
          Face.values.every((face) => other._boardsByFace[face] == _boardsByFace[face]);

  @override
  int get hashCode => Object.hashAll(Face.values.map((face) => _boardsByFace[face]));

  @override
  String toString() => 'CubeBoard(isCleared: $isCleared)';
}
