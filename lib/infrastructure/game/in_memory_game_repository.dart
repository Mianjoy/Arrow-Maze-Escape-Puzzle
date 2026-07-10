import '../../domain/domain.dart';

/// Implementación en memoria de [IGameRepository].
///
/// Sirve para desarrollar y probar la capa de aplicación/presentación sin
/// depender todavía de persistencia local real (SQLite/Hive); basta con
/// que cumpla el contrato del puerto de dominio.
class InMemoryGameRepository implements IGameRepository {
  final Map<String, Game> _gamesById = {};

  /// Guarda o actualiza una partida en el mapa interno.
  @override
  Future<void> save(Game game) async {
    _gamesById[game.id.value] = game;
  }

  /// Obtiene una partida por [id] o `null` si no existe.
  @override
  Future<Game?> findById(Identifier id) async {
    return _gamesById[id.value];
  }

  /// Lista las partidas en progreso del [playerId].
  @override
  Future<List<Game>> findActiveByPlayer(Identifier playerId) async {
    return _gamesById.values
        .where((game) => game.playerId == playerId && game.isPlayable)
        .toList();
  }
}
