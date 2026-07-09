import 'package:flutter/foundation.dart';

import '../../application/models/auth_session.dart';
import '../../application/use_cases/login_user_use_case.dart';
import '../../application/use_cases/logout_user_use_case.dart';
import '../../application/use_cases/register_user_use_case.dart';
import '../../application/use_cases/restore_auth_session_use_case.dart';

/// Controlador global de sesión: expone el estado de autenticación a la UI.
///
/// Centraliza login, registro, restauración de token y logout; notifica a los
/// widgets que escuchan cuando cambia [session].
class AuthSessionController extends ChangeNotifier {
  /// Crea el controlador con los casos de uso de autenticación inyectados.
  AuthSessionController({
    required LoginUserUseCase loginUserUseCase,
    required RegisterUserUseCase registerUserUseCase,
    required LogoutUserUseCase logoutUserUseCase,
    required RestoreAuthSessionUseCase restoreAuthSessionUseCase,
    AuthSession? initialSession,
  })  : _loginUserUseCase = loginUserUseCase,
        _registerUserUseCase = registerUserUseCase,
        _logoutUserUseCase = logoutUserUseCase,
        _restoreAuthSessionUseCase = restoreAuthSessionUseCase,
        _session = initialSession;

  final LoginUserUseCase _loginUserUseCase;
  final RegisterUserUseCase _registerUserUseCase;
  final LogoutUserUseCase _logoutUserUseCase;
  final RestoreAuthSessionUseCase _restoreAuthSessionUseCase;

  AuthSession? _session;
  bool _isLoading = false;
  Object? _error;

  /// Sesión activa, o `null` si el usuario no ha iniciado sesión.
  AuthSession? get session => _session;

  /// Indica si hay un JWT válido en memoria.
  bool get isAuthenticated => _session?.isAuthenticated ?? false;

  /// Indica si hay una operación de auth en curso.
  bool get isLoading => _isLoading;

  /// Último error de login/registro/logout para mostrar en la UI.
  Object? get error => _error;

  /// Restaura la sesión desde almacenamiento local (arranque de la app).
  Future<void> restoreSession() async {
    _session = await _restoreAuthSessionUseCase.execute();
    notifyListeners();
  }

  /// Inicia sesión con [username] y [password].
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _loginUserUseCase.execute(username: username, password: password);
      return true;
    } catch (error) {
      _error = error;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registra un usuario y deja la sesión iniciada automáticamente.
  Future<bool> register({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _registerUserUseCase.execute(username: username, password: password);
      return true;
    } catch (error) {
      _error = error;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cierra sesión y borra el token persistido.
  Future<void> logout() async {
    await _logoutUserUseCase.execute();
    _session = null;
    _error = null;
    notifyListeners();
  }

  /// Establece la sesión manualmente (tests o inyección E2E).
  void setSession(AuthSession? session) {
    _session = session;
    notifyListeners();
  }
}
