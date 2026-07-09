import 'package:flutter/foundation.dart';

import 'auth_session_controller.dart';

/// Controlador de la pantalla de registro de usuario.
///
/// Reutiliza [AuthSessionController] para registrar y dejar sesión activa.
class RegisterController extends ChangeNotifier {
  /// Crea el controlador con el [authSessionController] compartido de la app.
  RegisterController({required AuthSessionController authSessionController})
      : _authSessionController = authSessionController;

  final AuthSessionController _authSessionController;

  /// Indica si el formulario está enviándose.
  bool get isLoading => _authSessionController.isLoading;

  /// Error devuelto por el último intento de registro.
  Object? get error => _authSessionController.error;

  /// Registra al usuario; devuelve `true` si el alta y login automático tuvieron éxito.
  Future<bool> submit({
    required String username,
    required String password,
  }) {
    return _authSessionController.register(username: username, password: password);
  }
}
