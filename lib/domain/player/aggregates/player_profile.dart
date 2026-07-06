import 'package:meta/meta.dart';

import '../../shared/value_objects/identifier.dart';
import '../entities/player.dart';
import '../value_objects/player_statistics.dart';

/// Agregado raíz del perfil del jugador.
///
/// Agrupa la entidad [Player] con sus [PlayerStatistics] y expone
/// operaciones de dominio para registrar resultados de partidas.
@immutable
class PlayerProfile {
  /// Crea un perfil con [player] y [statistics] iniciales.
  const PlayerProfile({
    required this.player,
    this.statistics = const PlayerStatistics(),
  });

  /// Entidad de identidad del jugador.
  final Player player;

  /// Estadísticas acumuladas.
  final PlayerStatistics statistics;

  /// Identificador del jugador (atajo a [player.id]).
  Identifier get id => player.id;

  /// Registra una victoria y retorna un nuevo perfil inmutable.
  PlayerProfile recordVictory({
    required int moves,
    required int elapsedSeconds,
  }) {
    return PlayerProfile(
      player: player,
      statistics: statistics.recordWin(moves: moves, elapsedSeconds: elapsedSeconds),
    );
  }

  /// Registra una derrota o abandono.
  PlayerProfile recordDefeat({required int moves}) {
    return PlayerProfile(
      player: player,
      statistics: statistics.recordLoss(moves: moves),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfile &&
          runtimeType == other.runtimeType &&
          player == other.player &&
          statistics == other.statistics;

  @override
  int get hashCode => Object.hash(player, statistics);
}
