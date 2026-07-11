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
    this.score = 0,
    this.starsEarned,
    this.lossMessage,
    this.startedAt,
    this.finishedAt,
    this.totalPausedDuration = Duration.zero,
    this.pausedAt,
    StarRatingCalculator? starRatingCalculator,
  })  : assert(moveCount >= 0, 'moveCount must be non-negative'),
        assert(score >= 0, 'score must be non-negative'),
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

  /// Puntaje acumulado en la partida.
  ///
  /// Portado desde el dominio en español (`EstadoPartida.puntuacion` en la
  /// rama `Integracion`): se suman [_pointsPerExtractedArrow] puntos cada
  /// vez que una flecha es extraída con éxito.
  final int score;

  /// Puntos otorgados por cada flecha extraída exitosamente.
  static const int _pointsPerExtractedArrow = 100;

  /// Estrellas obtenidas al ganar (1–3); `null` si no ha ganado.
  final StarRating? starsEarned;

  /// Mensaje de derrota para mostrar al jugador.
  final GameLossMessage? lossMessage;

  /// Momento en que inició la partida.
  final DateTime? startedAt;

  /// Momento en que finalizó la partida.
  final DateTime? finishedAt;

  /// Tiempo acumulado en pausa (p. ej. al abrir Leaderboard o Ajustes).
  final Duration totalPausedDuration;

  /// Marca de inicio de la pausa activa; `null` si la partida no está pausada.
  final DateTime? pausedAt;

  /// Indica si la partida acepta movimientos.
  bool get isPlayable => status == GameStatus.inProgress;

  /// Indica si el jugador ganó.
  bool get isWon => status == GameStatus.won;

  /// Indica si el jugador perdió.
  bool get isLost => status == GameStatus.lost;

  /// Movimientos restantes antes de agotar el par del nivel.
  int get remainingMoves => (level.parMoves - moveCount).clamp(0, level.parMoves);

  /// Segundos restantes antes de agotar el límite del nivel.
  int get remainingSeconds =>
      (level.playableTimeLimitSeconds - elapsedSeconds).clamp(0, level.playableTimeLimitSeconds);

  /// Indica si quedan 10 segundos o menos en partida activa o pausada.
  bool get isTimeRunningLow =>
      (isPlayable || status == GameStatus.paused) && remainingSeconds <= 10;

  /// Segundos transcurridos desde [startedAt], descontando pausas.
  ///
  /// Usado al sincronizar progreso con el backend (`timeInSeconds` en `/progress/sync`).
  int get elapsedSeconds {
    final start = startedAt;
    if (start == null) return 0;

    final end = finishedAt ?? DateTime.now().toUtc();
    var active = end.difference(start) - totalPausedDuration;

    if (pausedAt != null && finishedAt == null) {
      active -= DateTime.now().toUtc().difference(pausedAt!);
    }

    return active.inSeconds.clamp(0, 1 << 30);
  }

  /// Porcentaje de flechas extraídas respecto al total del tablero (0–100).
  ///
  /// Portado desde el dominio en español (`EstadoPartida.porcentajeCompletado()`
  /// en la rama `Integracion`).
  double completionPercentage() {
    final total = board.arrows.length;
    if (total == 0) return 0;
    final extracted = board.arrows.where((arrow) => arrow.isExtracted).length;
    return (extracted / total) * 100;
  }

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

  /// Pausa una partida en curso, transicionando a [GameStatus.paused].
  ///
  /// Portado desde el dominio en español (`Partida.pausar()` en la rama
  /// `Integracion`). Solo es válido pausar una partida que está en progreso.
  Game pause() {
    if (status != GameStatus.inProgress) {
      throw InvalidMoveException('Game $id cannot be paused from status $status.');
    }
    return copyWith(
      status: GameStatus.paused,
      pausedAt: DateTime.now().toUtc(),
    );
  }

  /// Reanuda una partida pausada, volviendo a [GameStatus.inProgress].
  ///
  /// Portado desde el dominio en español (`Partida.reanudar()` en la rama
  /// `Integracion`). Solo es válido reanudar una partida que está pausada.
  Game resume() {
    if (status != GameStatus.paused) {
      throw InvalidMoveException('Game $id cannot be resumed from status $status.');
    }
    final pauseStarted = pausedAt;
    if (pauseStarted == null) {
      throw InvalidMoveException('Game $id cannot be resumed without a pause timestamp.');
    }

    final now = DateTime.now().toUtc();
    return copyWith(
      status: GameStatus.inProgress,
      clearPausedAt: true,
      totalPausedDuration: totalPausedDuration + now.difference(pauseStarted),
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
    final newScore = moveOutcome.result.isExtracted
        ? score + _pointsPerExtractedArrow
        : score;
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
          score: newScore,
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
          score: newScore,
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
        score: newScore,
      ),
      result: moveOutcome.result,
    );
  }

  /// Evalúa el límite de tiempo y retorna una partida perdida si se excedió.
  Game? _gameIfTimeExceeded() {
    final limit = level.playableTimeLimitSeconds;
    final start = startedAt;
    if (start == null) return null;

    final elapsed = elapsedSeconds;
    if (elapsed >= limit) {
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
    int? score,
    StarRating? starsEarned,
    GameLossMessage? lossMessage,
    bool clearLossMessage = false,
    DateTime? startedAt,
    DateTime? finishedAt,
    Duration? totalPausedDuration,
    DateTime? pausedAt,
    bool clearPausedAt = false,
  }) {
    return Game(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      level: level ?? this.level,
      board: board ?? this.board,
      status: status ?? this.status,
      moveCount: moveCount ?? this.moveCount,
      score: score ?? this.score,
      starsEarned: starsEarned ?? this.starsEarned,
      lossMessage: clearLossMessage ? null : (lossMessage ?? this.lossMessage),
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
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
      'Game(id: $id, status: $status, moves: $moveCount, score: $score, stars: ${starsEarned?.value})';
}
