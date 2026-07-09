import '../../application/ports/i_app_settings.dart';
import '../../domain/domain.dart';
import '../../interface_adapters/player_progress_json_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste [PlayerProgress] en [SharedPreferences] por jugador.
///
/// Cada usuario autenticado tiene su propia clave `progress_<userId>`.
class SharedPreferencesPlayerProgressRepository implements IPlayerProgressRepository {
  /// Crea el repositorio con [prefs] y el [mapper] de serialización.
  SharedPreferencesPlayerProgressRepository({
    required SharedPreferences prefs,
    PlayerProgressJsonMapper? mapper,
  })  : _prefs = prefs,
        _mapper = mapper ?? PlayerProgressJsonMapper();

  final SharedPreferences _prefs;
  final PlayerProgressJsonMapper _mapper;

  static const _keyPrefix = 'player_progress_';

  /// Factory asíncrona para uso en el composition root.
  static Future<SharedPreferencesPlayerProgressRepository> create({
    PlayerProgressJsonMapper? mapper,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesPlayerProgressRepository(prefs: prefs, mapper: mapper);
  }

  /// Genera la clave de almacenamiento para [playerId].
  String _storageKey(Identifier playerId) => '$_keyPrefix${playerId.value}';

  @override
  /// Guarda o actualiza el progreso del jugador en disco local.
  Future<void> save(PlayerProgress progress) async {
    await _prefs.setString(_storageKey(progress.playerId), _mapper.encode(progress));
  }

  @override
  /// Recupera el progreso persistido o `null` si el jugador es nuevo.
  Future<PlayerProgress?> findByPlayerId(Identifier playerId) async {
    final raw = _prefs.getString(_storageKey(playerId));
    if (raw == null) return null;
    return _mapper.decode(raw);
  }
}