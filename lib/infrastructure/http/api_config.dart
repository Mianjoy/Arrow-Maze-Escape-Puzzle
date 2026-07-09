/// Configuración del cliente HTTP hacia el backend Arrow Maze.
///
/// La URL base se puede sobreescribir en tiempo de compilación con
/// `--dart-define=API_BASE_URL=http://host:puerto` (útil en emulador
/// Android: `http://10.0.2.2:3000`, o en dispositivo físico: IP de la LAN).
class ApiConfig {
  /// Crea la configuración con la [baseUrl] del API REST.
  const ApiConfig({required this.baseUrl});

  /// Valor por defecto leído de `dart-define` o `http://localhost:3000`.
  static const ApiConfig fromEnvironment = ApiConfig(
    baseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
  );

  /// Origen del backend sin barra final (p. ej. `http://localhost:3000`).
  final String baseUrl;

  /// Concatena [baseUrl] con un [path] relativo (`/levels`, `/levels/:id`).
  ///
  /// Normaliza barras para evitar `//` o rutas mal formadas.
  Uri resolve(String path) {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
