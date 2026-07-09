import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../application/models/auth_session.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP para sincronizar progreso del jugador (`POST /progress/sync`).
///
/// Requiere un [AuthSession] válido porque el endpoint está protegido por JWT.
class ProgressApiClient {
  /// Crea el cliente con [config] y un [httpClient] inyectable para tests.
  ProgressApiClient({
    required ApiConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client();

  final ApiConfig _config;
  final http.Client _httpClient;

  /// Envía el progreso de un nivel completado al backend.
  ///
  /// El cuerpo sigue el contrato `ProgressSyncDto` del backend.
  Future<void> syncProgress({
    required AuthSession session,
    required String levelId,
    required int score,
    required int moves,
    required int timeInSeconds,
    required bool completed,
  }) async {
    final uri = _config.resolve('/progress/sync');
    final response = await _postJson(
      uri,
      headers: {
        'content-type': 'application/json',
        ...session.authorizationHeader,
      },
      body: {
        'userId': session.userId,
        'levelId': levelId,
        'score': score,
        'moves': moves,
        'timeInSeconds': timeInSeconds,
        'completed': completed,
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    throw _mapError(response, fallback: 'Progress sync failed');
  }

  /// Ejecuta POST con cuerpo JSON y cabeceras personalizadas.
  Future<http.Response> _postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    try {
      return await _httpClient
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw ApiException('Network error calling $uri: $error');
    }
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
      // Usar fallback si el cuerpo no es JSON válido.
    }
    return ApiException(fallback, statusCode: response.statusCode);
  }
}
