import 'dart:convert';

import '../../domain/domain.dart';

/// Adaptador que serializa y deserializa [PlayerProgress] a JSON persistible.
///
/// Usado por repositorios locales (`SharedPreferences`) para guardar el progreso
/// offline del jugador. Capa **Interface Adapters** (`lib/interface_adapters/`).
class PlayerProgressJsonMapper {
  /// Crea el mapper sin estado interno.
  const PlayerProgressJsonMapper();

  /// Serializa el agregado [progress] a un mapa JSON.
  Map<String, dynamic> toJson(PlayerProgress progress) {
    return {
      'playerId': progress.playerId.value,
      'levels': progress.levels.map(
        (id, lp) => MapEntry(id.value, _levelProgressToJson(lp)),
      ),
      if (progress.unlockedCollectibles.isNotEmpty)
        'unlockedCollectibles': progress.unlockedCollectibles.toList()..sort(),
    };
  }

  /// Reconstruye [PlayerProgress] desde un mapa JSON.
  PlayerProgress fromJson(Map<String, dynamic> json) {
    final playerId = Identifier(json['playerId'] as String);
    final levelsRaw = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = <Identifier, LevelProgress>{};

    for (final entry in levelsRaw.entries) {
      levels[Identifier(entry.key)] = _levelProgressFromJson(
        Identifier(entry.key),
        Map<String, dynamic>.from(entry.value as Map),
      );
    }

    final collectiblesRaw = json['unlockedCollectibles'];
    final unlockedCollectibles = collectiblesRaw is List
        ? collectiblesRaw.map((item) => _normalizeCollectibleId(item as String)).toSet()
        : <String>{};

    return PlayerProgress(
      playerId: playerId,
      levels: levels,
      unlockedCollectibles: unlockedCollectibles,
    );
  }

  /// Codifica el progreso como cadena JSON.
  String encode(PlayerProgress progress) => jsonEncode(toJson(progress));

  /// Decodifica una cadena JSON a [PlayerProgress].
  PlayerProgress decode(String raw) => fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static String _normalizeCollectibleId(String id) {
    if (id == 'collectible-milestone-22') return 'collectible-final';
    return id;
  }

  /// Convierte [LevelProgress] a mapa JSON.
  Map<String, dynamic> _levelProgressToJson(LevelProgress lp) {
    return {
      'status': lp.status.name,
      if (lp.bestMoveCount != null) 'bestMoveCount': lp.bestMoveCount,
      if (lp.bestTimeSeconds != null) 'bestTimeSeconds': lp.bestTimeSeconds,
      if (lp.bestStars != null) 'bestStars': lp.bestStars!.value,
      'completionCount': lp.completionCount,
    };
  }

  /// Reconstruye [LevelProgress] desde JSON.
  LevelProgress _levelProgressFromJson(Identifier levelId, Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'locked';
    final status = LevelProgressStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => LevelProgressStatus.locked,
    );
    final starsRaw = json['bestStars'];
    return LevelProgress(
      levelId: levelId,
      status: status,
      bestMoveCount: json['bestMoveCount'] as int?,
      bestTimeSeconds: json['bestTimeSeconds'] as int?,
      bestStars: starsRaw != null ? StarRating(starsRaw as int) : null,
      completionCount: json['completionCount'] as int? ?? 0,
    );
  }
}
