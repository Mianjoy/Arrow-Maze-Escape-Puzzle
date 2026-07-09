import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../application/models/auth_session.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP para los endpoints públicos de autenticación.
///
/// Traduce `POST /auth/register` y `POST /auth/login` a modelos de aplicación
/// sin conocer la capa de dominio del juego.
class AuthApiClient {
  /// Crea el cliente con [config] y un [httpClient] inyectable para tests.
  AuthApiClient({
    required ApiConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client();

  final ApiConfig _config;
  final http.Client _httpClient;

  /// Registra un usuario (`POST /auth/register`).
  ///
  /// Devuelve el `userId` y `username` creados. El registro no emite JWT;
  /// hay que llamar a [login] después.
  Future<({String userId, String username})> register({
    required String username,
    required String password,
  }) async {
    final uri = _config.resolve('/auth/register');
    final response = await _postJson(uri, {
      'username': username,
      'password': password,
    });

    if (response.statusCode == 201) {
      final body = _decodeObject(response.body, context: 'POST /auth/register');
      return (
        userId: _requireString(body, 'userId'),
        username: _requireString(body, 'username'),
      );
    }

    throw _mapError(response, fallback: 'Registration failed');
  }

  /// Inicia sesión (`POST /auth/login`) y devuelve la sesión con JWT.
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final uri = _config.resolve('/auth/login');
    final response = await _postJson(uri, {
      'username': username,
      'password': password,
    });

    if (response.statusCode == 200) {
      final body = _decodeObject(response.body, context: 'POST /auth/login');
      return AuthSession(
        token: _requireString(body, 'token'),
        userId: _requireString(body, 'userId'),
        username: _requireString(body, 'username'),
      );
    }

    throw _mapError(response, fallback: 'Login failed');
  }

  /// Ejecuta POST con cuerpo JSON y maneja errores de red.
  Future<http.Response> _postJson(Uri uri, Map<String, dynamic> body) async {
    try {
      return await _httpClient
          .post(
            uri,
            headers: {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw ApiException('Network error calling $uri: $error');
    }
  }

  /// Parsea el cuerpo como objeto JSON.
  Map<String, dynamic> _decodeObject(String body, {required String context}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw ApiException('$context: expected JSON object');
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('$context: invalid JSON ($error)');
    }
  }

  /// Extrae un campo string obligatorio del mapa JSON.
  String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw ApiException('Missing or invalid field "$key"');
  }

  /// Traduce respuestas de error del backend a [ApiException].
  ApiException _mapError(http.Response response, {required String fallback}) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          return ApiException(error['message'] as String, statusCode: response.statusCode);
        }
      }
    } catch (_) {
      // Ignorar JSON malformado y usar fallback.
    }
    return ApiException(fallback, statusCode: response.statusCode);
  }
}
