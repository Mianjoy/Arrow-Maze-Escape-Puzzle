import '../../infrastructure/http/api_exception.dart';
import '../../l10n/app_strings.dart';

/// Traduce el error crudo de login/registro (`ApiException` u otro) a un
/// mensaje amigable y localizado para mostrar en pantalla.
///
/// El backend distingue credenciales inválidas (401) de usuario ya existente
/// (409, solo en registro); `statusCode == null` significa que la petición
/// nunca llegó al servidor (sin red, backend caído).
String authErrorMessage(AppStrings strings, Object? error) {
  if (error == null) return '';

  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return strings.invalidCredentialsError;
      case 409:
        return strings.usernameAlreadyExistsError;
      case null:
        return strings.authConnectionError;
    }
  }

  return error.toString();
}
