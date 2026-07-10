import 'dart:convert';
import 'dart:io';

import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/level_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/level/level_repository_exception.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/level/remote_level_repository.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../support/mock_http_client.dart';

/// Pruebas de [RemoteLevelRepository] y [LevelApiClient] con HTTP simulado.
void main() {
  late Map<String, dynamic> simple1Json;

  setUp(() {
    final raw = File('docs/levels/simple-1.json').readAsStringSync();
    simple1Json = jsonDecode(raw) as Map<String, dynamic>;
    // El JSON canónico usa maxMoves: 5; el seed del backend usa 20.
    simple1Json = Map<String, dynamic>.from(simple1Json)..['maxMoves'] = 20;
  });

  group('LevelApiClient', () {
    test('should_throw_when_fetchAllLevels_body_is_not_an_array', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('{"id":"x"}', 200);
      });

      final api = LevelApiClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        httpClient: mockClient,
      );

      expect(
        () => api.fetchAllLevels(),
        throwsA(isA<LevelRepositoryException>()),
      );
    });
  });

  group('RemoteLevelRepository — with MockClient', () {
    test('should_map_and_sort_levels_from_GET_levels', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/levels');
        return http.Response(
          jsonEncode([
            {...simple1Json, 'levelNumber': 2, 'id': 'level-b'},
            simple1Json,
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteLevelRepository(
        apiClient: LevelApiClient(
          config: const ApiConfig(baseUrl: 'http://test'),
          httpClient: mockClient,
        ),
      );

      final levels = await repository.findAll();

      expect(levels, hasLength(2));
      expect(levels.first.id.value, 'simple-1');
      expect(levels.first.levelNumber, 1);
      expect(levels.last.id.value, 'level-b');
    });

    test('should_return_null_from_findById_on_404', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('{"error":"not found"}', 404);
      });

      final repository = RemoteLevelRepository(
        apiClient: LevelApiClient(
          config: const ApiConfig(baseUrl: 'http://test'),
          httpClient: mockClient,
        ),
      );

      final level = await repository.findById(const Identifier('missing'));
      expect(level, isNull);
    });

    test('should_map_findById_from_GET_levels_by_id_body', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, '/levels/simple-1');
        return http.Response(jsonEncode(simple1Json), 200);
      });

      final repository = RemoteLevelRepository(
        apiClient: LevelApiClient(
          config: const ApiConfig(baseUrl: 'http://test'),
          httpClient: mockClient,
        ),
      );

      final level = await repository.findById(const Identifier('simple-1'));
      expect(level, isNotNull);
      expect(level!.parMoves, 20);
    });

    test('should_throw_LevelRepositoryException_when_GET_levels_is_not_200', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('error', 500);
      });

      final repository = RemoteLevelRepository(
        apiClient: LevelApiClient(
          config: const ApiConfig(baseUrl: 'http://test'),
          httpClient: mockClient,
        ),
      );

      expect(
        () => repository.findAll(),
        throwsA(isA<LevelRepositoryException>()),
      );
    });
  });
}
