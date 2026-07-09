import 'dart:convert';

import 'package:http/http.dart' as http;

import '../level/level_repository_exception.dart';
import 'api_config.dart';

/// Cliente HTTP de bajo nivel para los endpoints públicos de catálogo de niveles.
///
/// Devuelve JSON crudo (`Map` / `List`) sin traducir al dominio; esa
/// responsabilidad pertenece a [LevelDtoMapper] vía [RemoteLevelRepository].
class LevelApiClient {
  /// Crea el cliente con [config] y un [httpClient] inyectable (tests usan [http.Client] mock).
  LevelApiClient({
    required ApiConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client();

  final ApiConfig _config;
  final http.Client _httpClient;

  /// Obtiene el listado completo (`GET /levels`) como lista de mapas JSON.
  ///
  /// Lanza [LevelRepositoryException] si la respuesta no es 200 o el cuerpo
  /// no es un array JSON de objetos.
  Future<List<Map<String, dynamic>>> fetchAllLevels() async {
    final uri = _config.resolve('/levels');
    final response = await _sendGet(uri);

    if (response.statusCode != 200) {
      throw LevelRepositoryException(
        'GET /levels failed',
        statusCode: response.statusCode,
      );
    }

    final decoded = _decodeJson(response.body);
    if (decoded is! List) {
      throw const LevelRepositoryException(
        'GET /levels: expected JSON array',
      );
    }

    return decoded
        .map((item) => _expectObject(item, context: 'GET /levels item'))
        .toList();
  }

  /// Obtiene un nivel por identificador (`GET /levels/:id`).
  ///
  /// Devuelve `null` si el servidor responde 404; lanza [LevelRepositoryException]
  /// para otros códigos de error o JSON inválido.
  Future<Map<String, dynamic>?> fetchLevelById(String id) async {
    final uri = _config.resolve('/levels/${Uri.encodeComponent(id)}');
    final response = await _sendGet(uri);

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw LevelRepositoryException(
        'GET /levels/$id failed',
        statusCode: response.statusCode,
      );
    }

    final decoded = _decodeJson(response.body);
    return _expectObject(decoded, context: 'GET /levels/$id');
  }

  /// Ejecuta la petición GET y traduce errores de socket/timeout a [LevelRepositoryException].
  Future<http.Response> _sendGet(Uri uri) async {
    try {
      return await _httpClient.get(uri).timeout(const Duration(seconds: 15));
    } catch (error) {
      throw LevelRepositoryException('Network error calling $uri: $error');
    }
  }

  /// Parsea el cuerpo de la respuesta como JSON.
  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (error) {
      throw LevelRepositoryException('Invalid JSON body: $error');
    }
  }

  /// Asegura que [value] sea un `Map<String, dynamic>` (objeto JSON).
  Map<String, dynamic> _expectObject(dynamic value, {required String context}) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw LevelRepositoryException('$context: expected JSON object');
  }
}
