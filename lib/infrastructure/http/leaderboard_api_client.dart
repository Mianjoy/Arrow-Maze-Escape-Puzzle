import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../application/models/leaderboard_entry.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP para consultar el ranking por nivel (`GET /leaderboard/:levelId`).
///
/// Endpoint público: no requiere JWT.
class LeaderboardApiClient {
  /// Crea el cliente con [config] y un [httpClient] inyectable para tests.
  LeaderboardApiClient({
    required ApiConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client();

  final ApiConfig _config;
  final http.Client _httpClient;

  /// Obtiene el top de jugadores para [levelId].
  ///
  /// [limit] acota la cantidad de entradas (por defecto 10 en el backend).
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required String levelId,
    int? limit,
  }) async {
    final path = '/leaderboard/${Uri.encodeComponent(levelId)}';
    final query = limit != null ? '?limit=$limit' : '';
    final uri = _config.resolve('$path$query');
    final response = await _sendGet(uri);

    if (response.statusCode != 200) {
      throw _mapError(response, fallback: 'Leaderboard fetch failed');
    }

    final decoded = _decodeJson(response.body);
    if (decoded is! List) {
      throw const ApiException('GET /leaderboard: expected JSON array');
    }

    return decoded.map(_parseEntry).toList();
  }

  /// Ejecuta GET y traduce errores de red.
  Future<http.Response> _sendGet(Uri uri) async {
    try {
      return await _httpClient.get(uri).timeout(const Duration(seconds: 15));
    } catch (error) {
      throw ApiException('Network error calling $uri: $error');
    }
  }

  /// Parsea el cuerpo como JSON.
  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (error) {
      throw ApiException('Invalid JSON body: $error');
    }
  }

  /// Convierte un elemento del array JSON en [LeaderboardEntry].
  LeaderboardEntry _parseEntry(dynamic value) {
    if (value is! Map) {
      throw const ApiException('Leaderboard entry must be a JSON object');
    }
    final map = value is Map<String, dynamic> ? value : Map<String, dynamic>.from(value);
    return LeaderboardEntry(
      username: _requireString(map, 'username'),
      highScore: _requireInt(map, 'highScore'),
      minMoves: _requireInt(map, 'minMoves'),
      minTimeInSeconds: _requireInt(map, 'minTimeInSeconds'),
    );
  }

  /// Extrae un campo string obligatorio.
  String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) return value;
    throw ApiException('Missing or invalid field "$key"');
  }

  /// Extrae un campo entero obligatorio.
  int _requireInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
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
      // Usar fallback.
    }
    return ApiException(fallback, statusCode: response.statusCode);
  }
}
