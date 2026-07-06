import 'package:meta/meta.dart';

import '../../board/aggregates/board.dart';
import '../../level/entities/level.dart';
import '../../shared/value_objects/identifier.dart';
import '../value_objects/game_status.dart';
import '../../shared/exceptions/invalid_move_exception.dart';
import '../../board/services/arrow_movement_engine.dart';
import '../../board/value_objects/move_result.dart';

/// Agregado raíz que representa una sesión de juego activa.
///
/// Orquesta [Level], [Board] y el estado de la partida ([GameStatus]).
/// Es el punto de entrada para ejecutar movimientos del jugador.
@immutable
class Game {
  /// Crea una partida con referencias a jugador, nivel y tablero.
  Game({
    required this.id,
    required this.playerId,
    required this.level,
    required this.board,
    this.status = GameStatus.ready,
    this.moveCount = 0,
    this.startedAt,
    this.finishedAt,
  }) : assert(moveCount >= 0, 'moveCount must be non-negative');

  /// Identificador único de la partida.
  final Identifier id;

  /// Jugador que participa en la partida.
  final Identifier playerId;

  /// Nivel que se está jugando.
  final Level level;

  /// Tablero actual de la partida.
  final Board board;

  /// Estado actual de la sesión.
  final GameStatus status;

  /// Cantidad de movimientos realizados.
  final int moveCount;

  /// Momento en que inició la partida.
  final DateTime? startedAt;

  /// Momento en que finalizó la partida.
  final DateTime? finishedAt;

  /// Indica si la partida acepta movimientos.
  bool get isPlayable => status == GameStatus.inProgress;

  /// Indica si el jugador ganó.
  bool get isWon => status == GameStatus.won;

  /// Inicia la partida, transicionando a [GameStatus.inProgress].
  Game start() {
    if (status != GameStatus.ready) {
      throw InvalidMoveException('Game $id cannot be started from status $status.');
    }
    return copyWith(
      status: GameStatus.inProgress,
      startedAt: DateTime.now().toUtc(),
    );
  }

  /// Ejecuta un movimiento sobre una flecha usando el [movementEngine].
  ///
  /// Retorna la partida actualizada y el [MoveResult] del movimiento.
  ({Game game, MoveResult result}) performMove({
    required Identifier arrowId,
    required ArrowMovementEngine movementEngine,
  }) {
    if (!isPlayable) {
      throw InvalidMoveException('Game $id is not in progress.');
    }

    final moveOutcome = movementEngine.attemptMove(
      board: board,
      arrowId: arrowId,
    );

    final updatedBoard = moveOutcome.board;
    final newMoveCount = moveCount + 1;
    final cleared = updatedBoard.isCleared;

    return (
      game: copyWith(
        board: updatedBoard,
        moveCount: newMoveCount,
        status: cleared ? GameStatus.won : status,
        finishedAt: cleared ? DateTime.now().toUtc() : finishedAt,
      ),
      result: moveOutcome.result,
    );
  }

  /// Retorna una copia con los campos indicados reemplazados.
  Game copyWith({
    Identifier? id,
    Identifier? playerId,
    Level? level,
    Board? board,
    GameStatus? status,
    int? moveCount,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return Game(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      level: level ?? this.level,
      board: board ?? this.board,
      status: status ?? this.status,
      moveCount: moveCount ?? this.moveCount,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          moveCount == other.moveCount;

  @override
  int get hashCode => Object.hash(id, status, moveCount);

  @override
  String toString() => 'Game(id: $id, status: $status, moves: $moveCount)';
}
