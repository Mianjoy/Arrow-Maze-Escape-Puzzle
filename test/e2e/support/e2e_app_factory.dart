import 'dart:convert';

import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/level_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/level/remote_level_repository.dart';
import 'package:arrow_maze_escape_puzzle/main.dart';
import 'package:http/http.dart' as http;

import '../../support/mock_http_client.dart';
import 'seed_catalog_fixture.dart';

/// Fábrica de dependencias para la suite E2E (sin fallback a assets locales).
///
/// Simula el backend con [MockHttpClient] y fuerza `fallbackToAssets: false`
/// para que cualquier fallo de integración HTTP sea visible en CI.
class E2eAppFactory {
  /// URL ficticia usada en tests; el mock no realiza red real.
  static const ApiConfig apiConfig = ApiConfig(baseUrl: 'http://e2e-test');

  /// Crea un [AppContainer] cableado solo al catálogo [catalog] simulado.
  static AppContainer createAppContainer({
    required List<Map<String, dynamic>> catalog,
  }) {
    final client = MockHttpClient((request) async {
      if (request.method == 'GET' && request.url.path == '/levels') {
        return http.Response(
          jsonEncode(catalog),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'GET' && request.url.path.startsWith('/levels/')) {
        final id = Uri.decodeComponent(request.url.pathSegments.last);
        Map<String, dynamic>? match;
        for (final level in catalog) {
          if (level['id'] == id) {
            match = level;
            break;
          }
        }
        if (match == null) {
          return http.Response('{"error":"not found"}', 404);
        }
        return http.Response(jsonEncode(match), 200);
      }

      return http.Response('not found', 404);
    });

    final remote = RemoteLevelRepository(
      apiClient: LevelApiClient(config: apiConfig, httpClient: client),
    );

    return AppContainer(
      levelRepository: remote,
      fallbackToAssets: false,
    );
  }

  /// Crea un contenedor con el fixture completo de 15 niveles del seed.
  static AppContainer createWithFullSeedCatalog() {
    return createAppContainer(catalog: SeedCatalogFixture.load());
  }
}
