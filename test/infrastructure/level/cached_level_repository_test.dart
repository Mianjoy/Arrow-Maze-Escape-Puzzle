import 'dart:convert';
import 'dart:io';

import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/level_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/level/cached_level_repository.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/level/level_repository_exception.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import '../../support/mock_http_client.dart';

/// Pruebas de [CachedLevelRepository]: caché write-through en
/// [SharedPreferences] cuando el backend responde, y respaldo offline
/// cuando la red falla.
void main() {
  late Map<String, dynamic> simple1Json;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final raw = File('docs/levels/simple-1.json').readAsStringSync();
    simple1Json = jsonDecode(raw) as Map<String, dynamic>;
    simple1Json = Map<String, dynamic>.from(simple1Json)..['maxMoves'] = 20;
  });

  CachedLevelRepository buildRepository(
    Future<http.Response> Function(http.Request request) handler, {
    SharedPreferences? prefs,
  }) {
    return CachedLevelRepository(
      apiClient: LevelApiClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        httpClient: MockHttpClient(handler),
      ),
      prefs: prefs!,
    );
  }

  group('CachedLevelRepository', () {
    test(
        'should_cache_levels_when_network_succeeds',
        () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final repository = buildRepository(
        (request) async => http.Response(jsonEncode([simple1Json]), 200),
        prefs: prefs,
      );

      // Act
      final levels = await repository.findAll();

      // Assert
      expect(levels, hasLength(1));
      expect(levels.first.id.value, 'simple-1');
      expect(prefs.getString('cached_levels_json'), isNotNull);
    });

    test(
        'should_return_cached_levels_when_network_fails_and_cache_exists',
        () async {
      // Arrange: previa carga exitosa deja el catálogo en disco.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_levels_json', jsonEncode([simple1Json]));

      final repository = buildRepository(
        (request) async => http.Response('error', 500),
        prefs: prefs,
      );

      // Act
      final levels = await repository.findAll();

      // Assert
      expect(levels, hasLength(1));
      expect(levels.first.id.value, 'simple-1');
    });

    test(
        'should_rethrow_when_network_fails_and_no_cache_exists',
        () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final repository = buildRepository(
        (request) async => http.Response('error', 500),
        prefs: prefs,
      );

      // Act & Assert
      expect(
        () => repository.findAll(),
        throwsA(isA<LevelRepositoryException>()),
      );
    });

    test(
        'should_refresh_cache_when_network_recovers',
        () async {
      // Arrange: catálogo viejo en disco, backend ahora responde uno nuevo.
      final prefs = await SharedPreferences.getInstance();
      final staleJson = Map<String, dynamic>.from(simple1Json)
        ..['id'] = 'stale-level';
      await prefs.setString('cached_levels_json', jsonEncode([staleJson]));

      final repository = buildRepository(
        (request) async => http.Response(jsonEncode([simple1Json]), 200),
        prefs: prefs,
      );

      // Act
      final levels = await repository.findAll();

      // Assert
      expect(levels.first.id.value, 'simple-1');
      final storedRaw = prefs.getString('cached_levels_json');
      final stored = jsonDecode(storedRaw!) as List<dynamic>;
      expect((stored.first as Map)['id'], 'simple-1');
    });

    test('findById busca en el catálogo ya resuelto por findAll', () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final repository = buildRepository(
        (request) async => http.Response(jsonEncode([simple1Json]), 200),
        prefs: prefs,
      );

      // Act
      final level = await repository.findById(
        (await repository.findAll()).first.id,
      );

      // Assert
      expect(level, isNotNull);
      expect(level!.id.value, 'simple-1');
    });
  });
}
