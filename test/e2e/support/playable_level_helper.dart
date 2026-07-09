import 'package:arrow_maze_escape_puzzle/application/use_cases/fire_arrow_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/start_game_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/interface_adapters/level_dto_mapper.dart';

import '../../application/support/fake_repositories.dart';

/// Utilidades de dominio/aplicación para validar que un nivel wire-format es jugable.
class PlayableLevelHelper {
  /// Mapper compartido por la suite E2E (misma config que producción).
  static const LevelDtoMapper mapper = LevelDtoMapper();

  /// Traduce JSON wire-format a [Level] de dominio.
  static Level mapWireLevel(Map<String, dynamic> json) {
    return mapper.fromJson(json);
  }

  /// Inicia una partida sobre [level] usando repositorio en memoria.
  static Future<Game> startGame(Level level) async {
    final gameRepository = FakeGameRepository();
    final useCase = StartGameUseCase(gameRepository: gameRepository);
    return useCase.execute(
      gameId: Identifier('e2e-${level.id.value}'),
      playerId: const Identifier('e2e-player'),
      level: level,
    );
  }

  /// Intenta disparar la flecha en [position]; retorna la partida actualizada.
  static Future<Game> tapCell(Game game, Position position) async {
    final gameRepository = FakeGameRepository()..save(game);
    final useCase = FireArrowUseCase(gameRepository: gameRepository);
    final outcome = await useCase.execute(game: game, position: position);
    return outcome.game;
  }

  /// Dispara flechas con vía libre repetidamente hasta ganar o quedar sin movimientos.
  ///
  /// Usa heurística greedy: en cada paso dispara la primera flecha cuya
  /// trayectoria no tiene bloqueo según [CollisionValidator].
  static Future<Game> solveGreedy(Game initial) async {
    var game = initial;
    var safety = 50;

    while (game.isPlayable && safety > 0) {
      safety -= 1;
      final next = _firstExtractableArrowHead(game);
      if (next == null) {
        break;
      }
      game = await tapCell(game, next);
      if (game.isWon || game.isLost) {
        return game;
      }
    }

    return game;
  }

  /// Devuelve la posición de la cabeza de la primera flecha que puede salir.
  static Position? _firstExtractableArrowHead(Game game) {
    const validator = CollisionValidator();
    for (final arrow in game.board.arrows) {
      if (!arrow.isMovable) {
        continue;
      }
      final blocking = validator.findBlockingPosition(board: game.board, arrow: arrow);
      if (blocking == null) {
        return arrow.position;
      }
    }
    return null;
  }

  /// Cuenta celdas marcadas como muro en el tablero inicial del nivel.
  static int countWalls(Level level) {
    final board = level.buildInitialBoard();
    return board.cells.where((cell) => cell.isWall).length;
  }
}
