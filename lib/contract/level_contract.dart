// Contrato de comunicación entre repos para la definición de un nivel.
//
// Espejo de `BackEnd-ArrowMaze/docs/contract/level.contract.ts`.
// Fuente de verdad: el archivo TypeScript del backend; cualquier cambio
// debe aplicarse allí primero y replicarse aquí.
//
// El dominio (`lib/domain/`) NO debe importar este archivo; solo
// `lib/interface_adapters/level_dto_mapper.dart` traduce estos DTOs
// a entidades de dominio. Ver también `docs/contract/README.md`.

/// Exige un entero en [json][key]; lanza [FormatException] si falta o el tipo no coincide.
int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('Expected int for "$key".');
}

/// Dificultad de un nivel en el wire format (siempre en MAYÚSCULAS en JSON).
///
/// Valores permitidos: `EASY`, `MEDIUM`, `HARD`, `EXPERT`.
/// El mapper las convierte al enum de dominio [LevelDifficulty] en minúsculas.
enum LevelDifficultyDto {
  /// Nivel introductorio.
  easy('EASY'),

  /// Complejidad media.
  medium('MEDIUM'),

  /// Alta densidad de flechas.
  hard('HARD'),

  /// Desafío máximo.
  expert('EXPERT');

  /// Crea el valor con su representación exacta en JSON.
  const LevelDifficultyDto(this.wireValue);

  /// Cadena tal como viaja en el JSON (`"EASY"`, `"MEDIUM"`, etc.).
  final String wireValue;

  /// Parsea la dificultad desde el campo `difficulty` del JSON.
  ///
  /// Acepta mayúsculas/minúsculas en la entrada y normaliza a mayúsculas.
  /// Lanza [FormatException] si el valor no es uno de los cuatro permitidos.
  static LevelDifficultyDto fromWire(String raw) {
    return LevelDifficultyDto.values.firstWhere(
      (d) => d.wireValue == raw.toUpperCase(),
      orElse: () => throw FormatException('Unknown level difficulty: $raw'),
    );
  }
}

/// Dirección cardinal de una flecha en el wire format.
///
/// Valores permitidos: `UP`, `DOWN`, `LEFT`, `RIGHT`.
enum ArrowDirectionDto {
  /// Hacia arriba (fila decreciente).
  up('UP'),

  /// Hacia abajo (fila creciente).
  down('DOWN'),

  /// Hacia la izquierda (columna decreciente).
  left('LEFT'),

  /// Hacia la derecha (columna creciente).
  right('RIGHT');

  /// Crea el valor con su representación exacta en JSON.
  const ArrowDirectionDto(this.wireValue);

  /// Cadena tal como viaja en el JSON.
  final String wireValue;

  /// Parsea la dirección desde el campo `direction` de una flecha.
  ///
  /// Lanza [FormatException] si el valor no es cardinal válido.
  static ArrowDirectionDto fromWire(String raw) {
    return ArrowDirectionDto.values.firstWhere(
      (d) => d.wireValue == raw.toUpperCase(),
      orElse: () => throw FormatException('Unknown arrow direction: $raw'),
    );
  }
}

/// Coordenada de una celda del tablero (fila/columna, base 0).
///
/// Usada en `exit`, `walls`, `head` y `body` de las flechas.
class CellPositionDto {
  /// Crea una posición con [row] (fila) y [col] (columna), ambas base 0.
  const CellPositionDto({required this.row, required this.col});

  /// Índice de fila (0 = borde superior del tablero).
  final int row;

  /// Índice de columna (0 = borde izquierdo del tablero).
  final int col;

  /// Construye un DTO desde un objeto JSON `{ "row": n, "col": m }`.
  ///
  /// Lanza [FormatException] si falta algún campo o no es entero.
  factory CellPositionDto.fromJson(Map<String, dynamic> json) {
    return CellPositionDto(
      row: _requireInt(json, 'row'),
      col: _requireInt(json, 'col'),
    );
  }

  /// Serializa al objeto JSON del contrato.
  Map<String, dynamic> toJson() => {'row': row, 'col': col};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellPositionDto && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// Máximo de segmentos de cuerpo por flecha (cabeza + cuerpo ≤ 3 celdas).
const int kMaxArrowBodySegments = 2;

/// Definición wire de una flecha: cabeza interactiva + segmentos de cuerpo.
///
/// Corresponde a cada elemento del array `arrows` en [StructuredLevelJsonDto].
class StructuredArrowJsonDto {
  /// Crea el DTO con [id], [direction], [head] y segmentos opcionales de [body].
  const StructuredArrowJsonDto({
    required this.id,
    required this.direction,
    required this.head,
    this.body = const [],
  });

  /// Identificador estable de la flecha (único dentro del nivel).
  final String id;

  /// Dirección hacia la que se dispara al tocar cualquier segmento.
  final ArrowDirectionDto direction;

  /// Celda cabeza: posición principal y punto de referencia del disparo.
  final CellPositionDto head;

  /// Celdas adicionales que ocupa el cuerpo (bloquean otras trayectorias).
  final List<CellPositionDto> body;

  /// Parsea una flecha desde un objeto del array `arrows`.
  ///
  /// El campo `body` es opcional en JSON; si falta, se asume lista vacía.
  factory StructuredArrowJsonDto.fromJson(Map<String, dynamic> json) {
    final bodyJson = json['body'];
    final body = bodyJson is List
        ? bodyJson
            .map((e) => CellPositionDto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <CellPositionDto>[];

    final id = json['id'] as String;
    if (body.length > kMaxArrowBodySegments) {
      throw FormatException(
        'Arrow "$id" has ${body.length} body segments; '
        'maximum allowed is $kMaxArrowBodySegments (3 cells total including head).',
      );
    }

    return StructuredArrowJsonDto(
      id: id,
      direction: ArrowDirectionDto.fromWire(json['direction'] as String),
      head: CellPositionDto.fromJson(Map<String, dynamic>.from(json['head'] as Map)),
      body: body,
    );
  }

  /// Serializa al objeto JSON del contrato.
  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction.wireValue,
        'head': head.toJson(),
        'body': body.map((p) => p.toJson()).toList(),
      };
}

/// Definición completa de un nivel tal como la expone el backend.
///
/// Es el tipo raíz de `GET /levels` y `GET /levels/:id`.
/// El frontend lo traduce a [Level] mediante [LevelDtoMapper].
class StructuredLevelJsonDto {
  /// Crea el DTO con todos los campos obligatorios del contrato.
  const StructuredLevelJsonDto({
    required this.id,
    required this.levelNumber,
    required this.difficulty,
    required this.maxMoves,
    required this.maxTimeInSeconds,
    required this.width,
    required this.height,
    required this.exit,
    required this.arrows,
    this.walls,
  });

  /// Identificador único del nivel (p. ej. `"simple-1"`, `"level-01"`).
  final String id;

  /// Orden en la progresión del jugador (entero ≥ 1).
  final int levelNumber;

  /// Dificultad en formato wire (`EASY`…`EXPERT`).
  final LevelDifficultyDto difficulty;

  /// Máximo de movimientos antes de perder (mapea a `parMoves` en dominio).
  final int maxMoves;

  /// Límite de tiempo en segundos (mapea a `timeLimit` en dominio).
  final int maxTimeInSeconds;

  /// Ancho del tablero en columnas (`boardDefinition.dimension.columns`).
  final int width;

  /// Alto del tablero en filas (`boardDefinition.dimension.rows`).
  final int height;

  /// Celda de salida (referencia visual; la victoria es vaciar todas las flechas).
  final CellPositionDto exit;

  /// Muros opcionales: celdas que bloquean trayectorias de flechas.
  final List<CellPositionDto>? walls;

  /// Lista de flechas del nivel (al menos una en niveles jugables).
  final List<StructuredArrowJsonDto> arrows;

  /// Parsea el JSON raíz devuelto por la API o leído de un archivo `.json`.
  ///
  /// Valida tipos y presencia de campos obligatorios; `walls` es opcional.
  factory StructuredLevelJsonDto.fromJson(Map<String, dynamic> json) {
    final wallsJson = json['walls'];
    final walls = wallsJson is List
        ? wallsJson
            .map((e) => CellPositionDto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : null;

    final arrowsJson = json['arrows'];
    if (arrowsJson is! List) {
      throw const FormatException('Expected array for arrows.');
    }

    return StructuredLevelJsonDto(
      id: json['id'] as String,
      levelNumber: _requireInt(json, 'levelNumber'),
      difficulty: LevelDifficultyDto.fromWire(json['difficulty'] as String),
      maxMoves: _requireInt(json, 'maxMoves'),
      maxTimeInSeconds: _requireInt(json, 'maxTimeInSeconds'),
      width: _requireInt(json, 'width'),
      height: _requireInt(json, 'height'),
      exit: CellPositionDto.fromJson(Map<String, dynamic>.from(json['exit'] as Map)),
      walls: walls,
      arrows: arrowsJson
          .map((e) => StructuredArrowJsonDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Serializa al JSON del contrato (para pruebas o escritura de niveles).
  Map<String, dynamic> toJson() => {
        'id': id,
        'levelNumber': levelNumber,
        'difficulty': difficulty.wireValue,
        'maxMoves': maxMoves,
        'maxTimeInSeconds': maxTimeInSeconds,
        'width': width,
        'height': height,
        'exit': exit.toJson(),
        if (walls != null && walls!.isNotEmpty) 'walls': walls!.map((w) => w.toJson()).toList(),
        'arrows': arrows.map((a) => a.toJson()).toList(),
      };
}
