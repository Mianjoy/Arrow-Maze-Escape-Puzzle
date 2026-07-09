import 'dart:convert';

import 'package:arrow_maze_escape_puzzle/application/models/auth_session.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/auth_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/mock_http_client.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://test');

  test('login devuelve AuthSession cuando el backend responde 200', () async {
    final client = MockHttpClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/login');
      return http.Response(
        jsonEncode({
          'token': 'jwt-abc',
          'userId': 'user-1',
          'username': 'player',
        }),
        200,
      );
    });

    final api = AuthApiClient(config: config, httpClient: client);
    final session = await api.login(username: 'player', password: 'password123');

    expect(session.token, 'jwt-abc');
    expect(session.userId, 'user-1');
    expect(session.username, 'player');
    expect(session.isAuthenticated, isTrue);
  });

  test('register devuelve userId y username en 201', () async {
    final client = MockHttpClient((request) async {
      expect(request.url.path, '/auth/register');
      return http.Response(
        jsonEncode({'userId': 'user-2', 'username': 'newbie'}),
        201,
      );
    });

    final api = AuthApiClient(config: config, httpClient: client);
    final result = await api.register(username: 'newbie', password: 'password123');

    expect(result.userId, 'user-2');
    expect(result.username, 'newbie');
  });
}
