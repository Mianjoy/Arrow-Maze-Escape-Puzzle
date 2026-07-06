import 'package:meta/meta.dart';

import '../../board/entities/board.dart';
import '../../level/aggregates/level.dart';
import '../../level/services/star_rating_calculator.dart';
import '../../level/value_objects/star_rating.dart';
import '../../shared/value_objects/identifier.dart';
import '../value_objects/game_status.dart';
import '../../shared/exceptions/invalid_move_exception.dart';
import '../../board/services/arrow_movement_engine.dart';
import '../../board/value_objects/move_result.dart';
import '../value_objects/game_loss_message.dart';

/// Agregado raíz que coordina una sesión de juego activa.
///
/// Centraliza todas las mutaciones de estado: movimientos, victoria,
/// derrota por exceso de movimientos o tiempo, y asignación de estrellas.
@immutable
class Game {
  /// Crea una partida a partir de un [level] y su [board] inicial.
  Game({
    required this.id,
    required this.playerId,
    required this.level,
    required this.board,
    this.status = GameStatus.ready,
    this.moveCount = 0,
    this.starsEarned,
    this.lossMessage,
    this.startedAt,
    this.finishedAt,
    StarRatingCalculator? starRatingCalculator,
  })  : assert(moveCount >= 0, 'moveCount must be non-negative'),
        _starRatingCalculator = starRatingCalculator ?? const StarRatingCalculator();

  final StarRatingCalculator _starRatingCalculator;

  /// Identificador único de la partida.
  final Identifier id;

  /// Jugador que participa en la partida.
  final Identifier playerId;

  /// Definición del nivel (agregado [Level]).
  final Level level;

  /// Estado actual del tablero durante la partida.
  final Board board;

  /// Estado actual de la sesión.
  final GameStatus status;

  /// Cantidad de movimientos realizados.
  final int moveCount;

  /// Estrellas obtenidas al ganar (1–3); `null` si no ha ganado.
  final StarRating? starsEarned;

  /// Mensaje de derrota para mostrar al jugador.
  final GameLossMessage? lossMessage;

  /// Momento en que inició la partida.
  final DateTime? startedAt;

  /// Momento en que finalizó la partida.
  final DateTime? finishedAt;

  /// Indica si la partida acepta movimientos.
  bool get isPlayable => status == GameStatus.inProgress;

  /// Indica si el jugador ganó.
  bool get isWon => status == GameStatus.won;

  /// Indica si el jugador perdió.
  bool get isLost => status == GameStatus.lost;

  /// Movimientos restantes antes de agotar el par del nivel.
  int get remainingMoves => (level.parMoves - moveCount).clamp(0, level.parMoves);

  /// Crea una partida lista para iniciar desde un [level] cargado.
  factory Game.fromLevel({
    required Identifier gameId,
    required Identifier playerId,
    required Level level,
  }) {
    return Game(
      id: gameId,
      playerId: playerId,
      level: level,
      board: level.buildInitialBoard(),
    );
  }

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
  /// Evalúa victoria, derrota por [Level.parMoves] y asigna [starsEarned].
  ({Game game, MoveResult result}) performMove({
    required Identifier arrowId,
    required ArrowMovementEngine movementEngine,
  }) {
    if (!isPlayable) {
      throw InvalidMoveException('Game $id is not in progress.');
    }

    final timeLoss = _gameIfTimeExceeded();
    if (timeLoss != null) {
      return (
        game: timeLoss,
        result: MoveResult.invalid(message: GameLossMessage.timeExceeded.text),
      );
    }

    final moveOutcome = movementEngine.attemptMove(
      board: board,
      arrowId: arrowId,
    );

    final updatedBoard = moveOutcome.board;
    final newMoveCount = moveCount + 1;
    final cleared = updatedBoard.isCleared;

    if (cleared) {
      final stars = _starRatingCalculator.calculate(
        moveCount: newMoveCount,
        optimalMoves: level.optimalMoves,
        parMoves: level.parMoves,
      );

      return (
        game: copyWith(
          board: updatedBoard,
          moveCount: newMoveCount,
          status: GameStatus.won,
          starsEarned: stars,
          finishedAt: DateTime.now().toUtc(),
        ),
        result: moveOutcome.result,
      );
    }

    if (newMoveCount >= level.parMoves) {
      return (
        game: copyWith(
          board: updatedBoard,
          moveCount: newMoveCount,
          status: GameStatus.lost,
          lossMessage: GameLossMessage.movesExceeded,
          finishedAt: DateTime.now().toUtc(),
        ),
        result: moveOutcome.result,
      );
    }

    return (
      game: copyWith(
        board: updatedBoard,
        moveCount: newMoveCount,
      ),
      result: moveOutcome.result,
    );
  }

  /// Evalúa el límite de tiempo y retorna una partida perdida si se excedió.
  Game? _gameIfTimeExceeded() {
    final limit = level.timeLimit;
    final start = startedAt;
    if (limit == null || start == null) return null;

    final elapsed = DateTime.now().toUtc().difference(start).inSeconds;
    if (elapsed > limit) {
      return copyWith(
        status: GameStatus.lost,
        lossMessage: GameLossMessage.timeExceeded,
        finishedAt: DateTime.now().toUtc(),
      );
    }
    return null;
  }

  /// Retorna una copia con los campos indicados reemplazados.
  Game copyWith({
    Identifier? id,
    Identifier? playerId,
    Level? level,
    Board? board,
    GameStatus? status,
    int? moveCount,
    StarRating? starsEarned,
    GameLossMessage? lossMessage,
    bool clearLossMessage = false,
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
      starsEarned: starsEarned ?? this.starsEarned,
      lossMessage: clearLossMessage ? null : (lossMessage ?? this.lossMessage),
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      starRatingCalculator: _starRatingCalculator,
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
  String toString() =>
      'Game(id: $id, status: $status, moves: $moveCount, stars: ${starsEarned?.value})';
}
