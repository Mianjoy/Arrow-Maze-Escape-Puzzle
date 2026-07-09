# Contrato de niveles — Arrow Maze

## Fuente de verdad

El formato **oficial** para intercambiar niveles entre repos es `StructuredLevelJsonDto`, definido en:

| Repo | Archivo |
|------|---------|
| **Backend** (canónico) | `BackEnd-ArrowMaze/docs/contract/level.contract.ts` |
| **Frontend** (espejo importable) | `Arrow-Maze-Escape-Puzzle/lib/contract/level_contract.dart` |

Cualquier cambio al contrato se hace **primero en el backend** y se replica en el espejo Dart del frontend.

## Decisión del equipo (08-jul-2026)

1. El modelo del **backend** es el definitivo: flechas con `head` + `body[]`, `exit`, `walls` opcionales, `maxMoves`, `maxTimeInSeconds`.
2. El JSON **legacy** del frontend (`board.cells`, `playerStart`, `parMoves`) queda **solo** para los 3 assets locales actuales hasta migrarlos; niveles nuevos y la API usan `StructuredLevelJsonDto`.
3. El dominio Flutter **no** conoce el wire format; la traducción vive en `lib/interface_adapters/level_dto_mapper.dart`.

## Mapeo wire format → dominio Flutter

| Campo wire (`StructuredLevelJsonDto`) | Campo dominio (`Level`) | Notas |
|---------------------------------------|-------------------------|-------|
| `id` | `id` | |
| `levelNumber` | `levelNumber` | Nuevo en dominio |
| `difficulty` (`EASY`…) | `difficulty` (`easy`…) | Mayúsculas → enum Dart |
| `maxMoves` | `parMoves` | Mismo significado |
| `maxTimeInSeconds` | `timeLimit` | |
| `height` / `width` | `boardDefinition.dimension` | `rows` = height, `cols` = width |
| `exit` | `boardDefinition.exit` + `playerStart` | `playerStart` usa `exit` (no hay avatar jugador) |
| `walls` | `boardDefinition.walls` | Bloquean trayectoria |
| `arrows[]` | `boardDefinition.arrowPlacements` | `id`, dirección, cabeza y cuerpo |

## Ejemplo canónico

Ver `docs/levels/simple-1.json` (mismo nivel que prueba `LevelJsonMapper` en el backend).

## Convenciones de código (acordadas)

- **Comentarios en español** (`///` dartdoc) en cada clase, método y campo público del contrato y del adaptador.
- **Nombres en inglés** en tipos y miembros (`StructuredLevelJsonDto`, `fromDto`, etc.).
- **No importar** `lib/contract/` desde `lib/domain/` — solo desde `lib/interface_adapters/`.

## Consumo en código

```dart
import 'package:arrow_maze_escape_puzzle/contract/level_contract.dart';
import 'package:arrow_maze_escape_puzzle/interface_adapters/level_dto_mapper.dart';

final dto = StructuredLevelJsonDto.fromJson(jsonDecode(raw));
final level = const LevelDtoMapper().fromDto(dto);
```
