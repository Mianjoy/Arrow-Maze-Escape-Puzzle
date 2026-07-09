import 'dart:convert';
import 'dart:io';

/// Cantidad de niveles que el seed del backend debe exponer (contrato E2E).
const int kSeedCatalogExpectedCount = 15;

/// Fixture del catálogo seed (`StructuredLevelJsonDto[]`) para pruebas E2E.
///
/// Espejo del `LEVEL_SEED_CATALOG` en `BackEnd-ArrowMaze`; si el backend
/// cambia el seed, actualizar este archivo o `test/fixtures/seed_catalog.json`.
class SeedCatalogFixture {
  /// Carga el catálogo desde `test/fixtures/seed_catalog.json` si existe;
  /// si no, construye el catálogo inline (mismos 15 ids que el backend).
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
      _level02,
      _level03,
      _level04,
      _level05,
      _level06,
      _level07,
      _level08,
      _level09,
      _level10,
      _level11,
      _level12,
      _level13,
      _level14,
      _level15,
    ];
  }
}

final Map<String, dynamic> _level02 = {
  'id': 'level-02',
  'levelNumber': 2,
  'difficulty': 'EASY',
  'maxMoves': 5,
  'maxTimeInSeconds': 90,
  'width': 2,
  'height': 1,
  'exit': {'row': 0, 'col': 1},
  'arrows': [
    {'id': 'a1', 'direction': 'RIGHT', 'head': {'row': 0, 'col': 0}, 'body': []},
  ],
};

final Map<String, dynamic> _level03 = {
  'id': 'level-03',
  'levelNumber': 3,
  'difficulty': 'MEDIUM',
  'maxMoves': 8,
  'maxTimeInSeconds': 90,
  'width': 3,
  'height': 3,
  'exit': {'row': 0, 'col': 2},
  'arrows': [
    {'id': 'b1', 'direction': 'RIGHT', 'head': {'row': 0, 'col': 0}, 'body': []},
    {'id': 'b2', 'direction': 'DOWN', 'head': {'row': 1, 'col': 1}, 'body': []},
  ],
};

final Map<String, dynamic> _level04 = {
  'id': 'level-04',
  'levelNumber': 4,
  'difficulty': 'MEDIUM',
  'maxMoves': 10,
  'maxTimeInSeconds': 120,
  'width': 3,
  'height': 3,
  'exit': {'row': 2, 'col': 2},
  'walls': [
    {'row': 1, 'col': 0},
  ],
  'arrows': [
    {'id': 'c1', 'direction': 'RIGHT', 'head': {'row': 0, 'col': 0}, 'body': []},
    {'id': 'c2', 'direction': 'UP', 'head': {'row': 2, 'col': 1}, 'body': []},
  ],
};

final Map<String, dynamic> _level05 = {
  'id': 'level-05',
  'levelNumber': 5,
  'difficulty': 'HARD',
  'maxMoves': 6,
  'maxTimeInSeconds': 120,
  'width': 2,
  'height': 1,
  'exit': {'row': 0, 'col': 1},
  'arrows': [
    {'id': 'd1', 'direction': 'RIGHT', 'head': {'row': 0, 'col': 0}, 'body': []},
  ],
};

final Map<String, dynamic> _level06 = {
  'id': 'level-06',
  'levelNumber': 6,
  'difficulty': 'EASY',
  'maxMoves': 5,
  'maxTimeInSeconds': 90,
  'width': 1,
  'height': 3,
  'exit': {'row': 2, 'col': 0},
  'arrows': [
    {'id': 'e1', 'direction': 'DOWN', 'head': {'row': 0, 'col': 0}, 'body': []},
  ],
};

final Map<String, dynamic> _level07 = {
  'id': 'level-07',
  'levelNumber': 7,
  'difficulty': 'EASY',
  'maxMoves': 5,
  'maxTimeInSeconds': 90,
  'width': 4,
  'height': 1,
  'exit': {'row': 0, 'col': 3},
  'arrows': [
    {'id': 'e2', 'direction': 'RIGHT', 'head': {'row': 0, 'col': 0}, 'body': []},
  ],
};

final Map<String, dynamic> _level08 = {
  'id': 'level-08',
  'levelNumber': 8,
  'difficulty': 'EASY',
  'maxMoves': 6,
  'maxTimeInSeconds': 90,
  'width': 5,
  'height': 1,
  'exit': {'row': 0, 'col': 4},
  'arrows': [
    {'id': 'e3', 'direction': 'LEFT', 'head': {'row': 0, 'col': 1}, 'body': []},
    {'id': 'e4', 'direction': 'RIGHT', 'head': {'row': 0, 'col': 3}, 'body': []},
  ],
};

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

final Map<String, dynamic> _level10 = {
  'id': 'level-10',
  'levelNumber': 10,
  'difficulty': 'MEDIUM',
  'maxMoves': 10,
  'maxTimeInSeconds': 120,
  'width': 4,
  'height': 4,
  'exit': {'row': 0, 'col': 3},
  'arrows': [
    {'id': 'g1', 'direction': 'UP', 'head': {'row': 3, 'col': 1}, 'body': []},
    {'id': 'g2', 'direction': 'RIGHT', 'head': {'row': 1, 'col': 0}, 'body': []},
    {'id': 'g3', 'direction': 'DOWN', 'head': {'row': 0, 'col': 2}, 'body': []},
  ],
};

final Map<String, dynamic> _level11 = {
  'id': 'level-11',
  'levelNumber': 11,
  'difficulty': 'MEDIUM',
  'maxMoves': 12,
  'maxTimeInSeconds': 120,
  'width': 4,
  'height': 4,
  'exit': {'row': 3, 'col': 3},
  'walls': [
    {'row': 2, 'col': 1},
  ],
  'arrows': [
    {'id': 'h1', 'direction': 'RIGHT', 'head': {'row': 0, 'col': 0}, 'body': []},
    {'id': 'h2', 'direction': 'UP', 'head': {'row': 3, 'col': 2}, 'body': []},
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

final Map<String, dynamic> _level13 = {
  'id': 'level-13',
  'levelNumber': 13,
  'difficulty': 'HARD',
  'maxMoves': 15,
  'maxTimeInSeconds': 150,
  'width': 3,
  'height': 3,
  'exit': {'row': 2, 'col': 2},
  'arrows': [
    {'id': 'i1', 'direction': 'DOWN', 'head': {'row': 0, 'col': 0}, 'body': []},
    {'id': 'i2', 'direction': 'DOWN', 'head': {'row': 0, 'col': 2}, 'body': []},
    {'id': 'i3', 'direction': 'RIGHT', 'head': {'row': 2, 'col': 0}, 'body': []},
  ],
};

final Map<String, dynamic> _level14 = {
  'id': 'level-14',
  'levelNumber': 14,
  'difficulty': 'HARD',
  'maxMoves': 14,
  'maxTimeInSeconds': 150,
  'width': 5,
  'height': 5,
  'exit': {'row': 4, 'col': 4},
  'walls': [
    {'row': 2, 'col': 2},
    {'row': 1, 'col': 2},
  ],
  'arrows': [
    {'id': 'j1', 'direction': 'RIGHT', 'head': {'row': 0, 'col': 0}, 'body': []},
    {'id': 'j2', 'direction': 'DOWN', 'head': {'row': 4, 'col': 0}, 'body': []},
    {'id': 'j3', 'direction': 'UP', 'head': {'row': 4, 'col': 4}, 'body': []},
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
    {'id': 'k-top', 'direction': 'RIGHT', 'head': {'row': 0, 'col': 3}, 'body': []},
  ],
};
