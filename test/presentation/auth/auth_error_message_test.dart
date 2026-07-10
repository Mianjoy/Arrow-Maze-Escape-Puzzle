import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_exception.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/auth/auth_error_message.dart';
import 'package:test/test.dart';

/// Pruebas de `authErrorMessage`: mapea `ApiException` por `statusCode` a un
/// mensaje amigable y localizado, en vez de mostrar la excepción cruda.
void main() {
  const strings = AppStringsEs();

  test('should_return_empty_string_when_error_is_null', () {
    expect(authErrorMessage(strings, null), '');
  });

  test('should_return_invalid_credentials_message_for_401', () {
    const error = ApiException('Invalid username or password', statusCode: 401);
    expect(authErrorMessage(strings, error), strings.invalidCredentialsError);
  });

  test('should_return_username_taken_message_for_409', () {
    const error = ApiException('A user with username "x" already exists', statusCode: 409);
    expect(authErrorMessage(strings, error), strings.usernameAlreadyExistsError);
  });

  test('should_return_connection_error_message_when_status_code_is_null', () {
    const error = ApiException('Network error calling http://test: SocketException');
    expect(authErrorMessage(strings, error), strings.authConnectionError);
  });

  test('should_fallback_to_raw_message_for_unmapped_status_codes', () {
    const error = ApiException('Something else went wrong', statusCode: 500);
    expect(authErrorMessage(strings, error), error.toString());
  });
}
