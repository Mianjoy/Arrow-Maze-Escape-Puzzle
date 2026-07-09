import 'package:meta/meta.dart';

/// Value object con estadísticas acumuladas del jugador.
@immutable
class PlayerStatistics {
  /// Crea estadísticas con contadores iniciales.
  const PlayerStatistics({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.totalMoves = 0,
    this.bestTimeSeconds,
  });

  /// Partidas iniciadas.
  final int gamesPlayed;

  /// Partidas ganadas.
  final int gamesWon;

  /// Movimientos totales realizados.
  final int totalMoves;

  /// Mejor tiempo registrado en segundos (`null` si aún no hay victorias).
  final int? bestTimeSeconds;

  /// Porcentaje de victorias (0.0 a 1.0).
  double get winRate => gamesPlayed == 0 ? 0.0 : gamesWon / gamesPlayed;

  /// Retorna una copia incrementando las estadísticas según una victoria.
  PlayerStatistics recordWin({required int moves, required int elapsedSeconds}) {
    final newBest = bestTimeSeconds == null
        ? elapsedSeconds
        : (elapsedSeconds < bestTimeSeconds! ? elapsedSeconds : bestTimeSeconds);

    return PlayerStatistics(
      gamesPlayed: gamesPlayed + 1,
      gamesWon: gamesWon + 1,
      totalMoves: totalMoves + moves,
      bestTimeSeconds: newBest,
    );
  }

  /// Retorna una copia incrementando partidas jugadas sin victoria.
  PlayerStatistics recordLoss({required int moves}) {
    return PlayerStatistics(
      gamesPlayed: gamesPlayed + 1,
      gamesWon: gamesWon,
      totalMoves: totalMoves + moves,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStatistics &&
          runtimeType == other.runtimeType &&
          gamesPlayed == other.gamesPlayed &&
          gamesWon == other.gamesWon &&
          totalMoves == other.totalMoves &&
          bestTimeSeconds == other.bestTimeSeconds;

  @override
  int get hashCode => Object.hash(gamesPlayed, gamesWon, totalMoves, bestTimeSeconds);
}
