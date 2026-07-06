/// Barrel export de la capa de dominio de Arrow Maze.
///
/// Importar este archivo expone todas las entidades, agregados,
/// value objects, servicios y contratos de repositorio del dominio.
library domain;

// Shared
export 'shared/enums/arrow_direction.dart';
export 'shared/value_objects/direction.dart';
export 'shared/value_objects/identifier.dart';
export 'shared/value_objects/position.dart';
export 'shared/exceptions/domain_exception.dart';
export 'shared/exceptions/invalid_move_exception.dart';
export 'shared/exceptions/cell_occupied_exception.dart';

// Board
export 'board/entities/arrow.dart';
export 'board/entities/board.dart';
export 'board/entities/cell.dart';
export 'board/value_objects/arrow_state.dart';
export 'board/value_objects/board_dimension.dart';
export 'board/value_objects/board_generation_config.dart';
export 'board/value_objects/cell_state.dart';
export 'board/value_objects/move_result.dart';
export 'board/factories/board_factory.dart';
export 'board/factories/cell_factory.dart';
export 'board/services/arrow_movement_engine.dart';
export 'board/services/collision_validator.dart';
export 'board/services/i_collision_validator.dart';
export 'board/services/i_random_board_generator.dart';
export 'board/services/random_board_generator.dart';
export 'board/events/arrow_extracted_event.dart';
export 'board/events/arrow_blocked_event.dart';

// Level
export 'level/aggregates/level.dart';
export 'level/value_objects/level_board_definition.dart';
export 'level/value_objects/level_cell_data.dart';
export 'level/value_objects/level_difficulty.dart';
export 'level/value_objects/player_start.dart';
export 'level/value_objects/star_rating.dart';
export 'level/factories/level_factory.dart';
export 'level/services/shortest_path_calculator.dart';
export 'level/services/star_rating_calculator.dart';

// Player
export 'player/entities/player.dart';
export 'player/aggregates/player_profile.dart';
export 'player/value_objects/player_statistics.dart';

// Game
export 'game/aggregates/game.dart';
export 'game/value_objects/game_status.dart';
export 'game/value_objects/game_loss_message.dart';
export 'game/events/game_won_event.dart';

// Progress
export 'progress/aggregates/player_progress.dart';
export 'progress/value_objects/level_progress.dart';
export 'progress/value_objects/level_progress_status.dart';

// Repositories
export 'repositories/i_game_repository.dart';
export 'repositories/i_player_profile_repository.dart';
export 'repositories/i_player_progress_repository.dart';
