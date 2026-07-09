import 'package:http/http.dart' as http;

/// Cliente HTTP de prueba que delega cada petición en un [handler] síncrono/async.
///
/// Usado en tests de [RemoteLevelRepository] y en la suite E2E para simular
/// `GET /levels` sin levantar el backend real.
class MockHttpClient extends http.BaseClient {
  /// Crea el mock con el [handler] que produce la [http.Response] por petición.
  MockHttpClient(this._handler);

  final Future<http.Response> Function(http.Request request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(http.Request(request.method, request.url));
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
