import 'package:shared_preferences/shared_preferences.dart';

import '../../application/models/auth_session.dart';
import '../../application/ports/i_token_storage.dart';

/// Persiste la sesión JWT en [SharedPreferences] del dispositivo.
///
/// Usado en producción para restaurar la sesión sin pedir login en cada arranque.
class SharedPreferencesTokenStorage implements ITokenStorage {
  SharedPreferencesTokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _usernameKey = 'auth_username';

  /// Crea la instancia tras inicializar el plugin de preferencias.
  static Future<SharedPreferencesTokenStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesTokenStorage(prefs);
  }

  @override
  /// Guarda token, userId y username en preferencias locales.
  Future<void> saveSession(AuthSession session) async {
    await _prefs.setString(_tokenKey, session.token);
    await _prefs.setString(_userIdKey, session.userId);
    await _prefs.setString(_usernameKey, session.username);
  }

  @override
  /// Lee la sesión persistida; devuelve `null` si falta el token.
  Future<AuthSession?> readSession() async {
    final token = _prefs.getString(_tokenKey);
    final userId = _prefs.getString(_userIdKey);
    final username = _prefs.getString(_usernameKey);
    if (token == null || userId == null || username == null) {
      return null;
    }
    return AuthSession(token: token, userId: userId, username: username);
  }

  @override
  /// Elimina las claves de sesión del almacenamiento local.
  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_usernameKey);
  }
}
