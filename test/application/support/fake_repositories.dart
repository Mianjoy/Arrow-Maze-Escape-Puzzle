import 'package:arrow_maze_escape_puzzle/domain/domain.dart';

/// Fake en memoria de [ILevelRepository] para pruebas de casos de uso.
class FakeLevelRepository implements ILevelRepository {
  FakeLevelRepository([List<Level> initialLevels = const []])
      : _levels = List.of(initialLevels);

  final List<Level> _levels;

  @override
  Future<List<Level>> findAll() async => List.unmodifiable(_levels);

  @override
  Future<Level?> findById(Identifier id) async {
    for (final level in _levels) {
      if (level.id == id) return level;
    }
    return null;
  }
}

/// Fake en memoria de [IGameRepository] para pruebas de casos de uso.
class FakeGameRepository implements IGameRepository {
  final Map<String, Game> _gamesById = {};

  List<Game> get savedGames => _gamesById.values.toList();

  @override
  Future<void> save(Game game) async {
    _gamesById[game.id.value] = game;
  }

  @override
  Future<Game?> findById(Identifier id) async => _gamesById[id.value];

  @override
  Future<List<Game>> findActiveByPlayer(Identifier playerId) async {
    return _gamesById.values
        .where((game) => game.playerId == playerId && game.isPlayable)
        .toList();
  }
}

/// Construye un [Level] mínimo de prueba (2x2, sin celdas predefinidas).
Level buildTestLevel({String id = 'level-test'}) {
  return Level(
    id: Identifier(id),
    difficulty: LevelDifficulty.easy,
    boardDefinition: const LevelBoardDefinition(
      dimension: BoardDimension(rows: 2, columns: 2),
      cells: [],
    ),
    playerStart: const PlayerStart(position: Position(row: 0, column: 0)),
    parMoves: 5,
    optimalMoves: 1,
  );
}
