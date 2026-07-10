import 'package:flutter/foundation.dart';

import 'auth_session_controller.dart';

/// Controlador de la pantalla de inicio de sesión.
///
/// Delega la autenticación en [AuthSessionController] y expone estado local
/// de validación de formulario.
class LoginController extends ChangeNotifier {
  /// Crea el controlador con el [authSessionController] compartido de la app.
  ///
  /// Se suscribe a sus cambios y los reenvía como propios: [isLoading] y
  /// [error] leen del controlador compartido, así que sin este reenvío la UI
  /// (que escucha `this`, no `authSessionController`) nunca se reconstruiría
  /// tras un login fallido — el error quedaría calculado pero invisible.
  LoginController({required AuthSessionController authSessionController})
      : _authSessionController = authSessionController {
    _authSessionController.addListener(notifyListeners);
  }

  final AuthSessionController _authSessionController;

  @override
  void dispose() {
    _authSessionController.removeListener(notifyListeners);
    super.dispose();
  }

  /// Indica si el formulario está enviándose.
  bool get isLoading => _authSessionController.isLoading;

  /// Error devuelto por el último intento de login.
  Object? get error => _authSessionController.error;

  /// Intenta iniciar sesión; devuelve `true` si las credenciales son válidas.
  Future<bool> submit({
    required String username,
    required String password,
  }) {
    return _authSessionController.login(username: username, password: password);
  }
}
