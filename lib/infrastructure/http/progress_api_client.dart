import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../application/models/auth_session.dart';
import '../../application/models/remote_player_progress.dart';
import '../../application/ports/i_progress_api_client.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP para sincronizar progreso del jugador (`POST /progress/sync`).
///
/// Requiere un [AuthSession] válido porque el endpoint está protegido por JWT.
class ProgressApiClient implements IProgressApiClient {
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
  @override
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

  /// Sincroniza los coleccionables desbloqueados del jugador.
  @override
  Future<void> syncCollectibles({
    required AuthSession session,
    required List<String> collectibleIds,
  }) async {
    final uri = _config.resolve('/progress/collectibles/sync');
    final response = await _postJson(
      uri,
      headers: {
        'content-type': 'application/json',
        ...session.authorizationHeader,
      },
      body: {
        'collectibleIds': collectibleIds,
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    throw _mapError(response, fallback: 'Collectibles sync failed');
  }

  /// Descarga todo el progreso del jugador autenticado (`GET /progress`).
  ///
  /// El backend identifica al usuario por el JWT; devuelve la lista de niveles
  /// con registro para que el cliente la fusione con su progreso local.
  @override
  Future<RemotePlayerProgress> fetchProgress(AuthSession session) async {
    final uri = _config.resolve('/progress');
    final http.Response response;
    try {
      response = await _httpClient
          .get(uri, headers: session.authorizationHeader)
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw ApiException('Network error calling $uri: $error');
    }

    if (response.statusCode != 200) {
      throw _mapError(response, fallback: 'Fetch progress failed');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['levels'] is! List) {
      throw const ApiException('GET /progress: expected { levels: [...] }');
    }

    final collectiblesRaw = decoded['collectibles'];
    final collectibles = collectiblesRaw is List
        ? collectiblesRaw.map((item) => item as String).toList()
        : <String>[];

    return RemotePlayerProgress(
      levels: (decoded['levels'] as List)
          .cast<Map<String, dynamic>>()
          .map(RemoteLevelProgress.fromJson)
          .toList(),
      collectibles: collectibles,
    );
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
