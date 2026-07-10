import '../../domain/domain.dart';
import '../ports/i_use_case_logger.dart';
import 'fire_arrow_use_case.dart';

/// Aspecto AOP de logging/trazabilidad sobre [FireArrowUseCase].
///
/// Registra el estado del tablero antes y después de cada movimiento
/// (flechas restantes, movimientos usados, estado de la partida) y la
/// duración de la ejecución, sin que [FireArrowUseCase] ni [GameController]
/// contengan una sola llamada al logger — el cross-cutting concern está
/// completamente separado del código de negocio, aplicado por composición
/// (Decorator) en el composition root (`AppContainer`).
class LoggingFireArrowUseCaseDecorator implements IFireArrowUseCase {
  /// Envuelve [inner] con trazabilidad, reportando a través de [logger].
  const LoggingFireArrowUseCaseDecorator({
    required IFireArrowUseCase inner,
    required IUseCaseLogger logger,
  })  : _inner = inner,
        _logger = logger;

  final IFireArrowUseCase _inner;
  final IUseCaseLogger _logger;

  /// Delega el disparo en [inner] registrando trazas de inicio, fin y error.
  @override
  Future<({Game game, MoveResult result})> execute({
    required Game game,
    required Position position,
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger.log(
      'FireArrowUseCase.execute START game=${game.id.value} '
      'position=$position arrowsRemaining=${game.board.activeArrows.length} '
      'moveCount=${game.moveCount}',
    );

    try {
      final outcome = await _inner.execute(game: game, position: position);

      stopwatch.stop();
      _logger.log(
        'FireArrowUseCase.execute END game=${game.id.value} '
        'status=${outcome.game.status.name} '
        'arrowsRemaining=${outcome.game.board.activeArrows.length} '
        'moveCount=${outcome.game.moveCount} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );

      return outcome;
    } catch (error) {
      stopwatch.stop();
      _logger.log(
        'FireArrowUseCase.execute FAILED game=${game.id.value} '
        'elapsedMs=${stopwatch.elapsedMilliseconds} error=$error',
      );
      rethrow;
    }
  }
}
