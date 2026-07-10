import 'dart:convert';
import 'dart:io';

/// Cantidad de niveles que el seed del backend debe exponer (contrato E2E).
///
/// El catálogo se redujo de 15 a 4 niveles al depurar las flechas sin cuerpo
/// (ver `kMinArrowBodySegments` / `arrowPlacementValidator` en el backend):
/// el equipo diseñará manualmente los reemplazos de los niveles retirados.
/// Este número crece de vuelta a 15 a medida que se agreguen niveles nuevos
/// conformes a la regla.
const int kSeedCatalogExpectedCount = 4;

/// Fixture del catálogo seed (`StructuredLevelJsonDto[]`) para pruebas E2E.
///
/// Espejo del `LEVEL_SEED_CATALOG` en `BackEnd-ArrowMaze`; si el backend
/// cambia el seed, actualizar este archivo o `test/fixtures/seed_catalog.json`.
class SeedCatalogFixture {
  /// Carga el catálogo desde `test/fixtures/seed_catalog.json` si existe;
  /// si no, construye el catálogo inline (mismos ids que el backend).
  static List<Map<String, dynamic>> load() {
    final file = File('test/fixtures/seed_catalog.json');
    if (file.existsSync()) {
      final decoded = jsonDecode(file.readAsStringSync());
      return (decoded as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return _inlineCatalog();
  }

  /// Devuelve un único nivel por [id] o lanza si no está en el catálogo.
  static Map<String, dynamic> levelById(String id) {
    return load().firstWhere(
      (level) => level['id'] == id,
      orElse: () => throw StateError('Seed fixture missing level: $id'),
    );
  }

  /// Construye `simple-1` desde `docs/levels/simple-1.json` con `maxMoves` del seed.
  static Map<String, dynamic> _loadSimple1() {
    final raw = File('docs/levels/simple-1.json').readAsStringSync();
    final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    json['maxMoves'] = 20;
    json['maxTimeInSeconds'] = 120;
    return json;
  }

  /// Catálogo inline cuando no hay archivo JSON (CI y desarrollo local).
  static List<Map<String, dynamic>> _inlineCatalog() {
    return [
      _loadSimple1(),
      _level09,
      _level12,
      _level15,
    ];
  }
}

final Map<String, dynamic> _level09 = {
  'id': 'level-09',
  'levelNumber': 9,
  'difficulty': 'MEDIUM',
  'maxMoves': 12,
  'maxTimeInSeconds': 120,
  'width': 4,
  'height': 3,
  'exit': {'row': 2, 'col': 2},
  'arrows': [
    {
      'id': 'f-chain-a',
      'direction': 'DOWN',
      'head': {'row': 0, 'col': 2},
      'body': [
        {'row': 0, 'col': 1},
      ],
    },
    {
      'id': 'f-chain-b',
      'direction': 'RIGHT',
      'head': {'row': 1, 'col': 3},
      'body': [
        {'row': 1, 'col': 2},
        {'row': 1, 'col': 1},
      ],
    },
  ],
};

final Map<String, dynamic> _level12 = {
  'id': 'level-12',
  'levelNumber': 12,
  'difficulty': 'HARD',
  'maxMoves': 8,
  'maxTimeInSeconds': 120,
  'width': 4,
  'height': 1,
  'exit': {'row': 0, 'col': 0},
  'arrows': [
    {
      'id': 'h3',
      'direction': 'LEFT',
      'head': {'row': 0, 'col': 3},
      'body': [
        {'row': 0, 'col': 2},
        {'row': 0, 'col': 1},
      ],
    },
  ],
};

final Map<String, dynamic> _level15 = {
  'id': 'level-15',
  'levelNumber': 15,
  'difficulty': 'EXPERT',
  'maxMoves': 20,
  'maxTimeInSeconds': 180,
  'width': 6,
  'height': 6,
  'exit': {'row': 0, 'col': 5},
  'arrows': [
    {
      'id': 'k-trapped',
      'direction': 'DOWN',
      'head': {'row': 1, 'col': 2},
      'body': [
        {'row': 0, 'col': 2},
      ],
    },
    {
      'id': 'k-free',
      'direction': 'RIGHT',
      'head': {'row': 3, 'col': 4},
      'body': [
        {'row': 3, 'col': 3},
        {'row': 3, 'col': 2},
        {'row': 3, 'col': 1},
      ],
    },
    {
      'id': 'k-top',
      'direction': 'RIGHT',
      'head': {'row': 0, 'col': 3},
      'body': [
        {'row': 1, 'col': 3},
      ],
    },
  ],
};
