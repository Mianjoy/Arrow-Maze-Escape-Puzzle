# Registro de Uso de Inteligencia Artificial

Este documento registra cada consulta realizada a herramientas de IA durante el desarrollo del proyecto **Arrow Maze Escape Puzzle**.

---

## Consulta #1 — Creación de la capa de dominio

**Tarea o problema abordado.**

Diseñar e implementar la capa de dominio completa del juego **Arrow Maze** siguiendo **Patrones de Diseño** y **Clean Architecture**, incluyendo únicamente dicha capa en esta etapa. Se requerían como entidades principales: `Player`, `Board`, `Cell` y `Level`, con libertad para proponer entidades adicionales a revisión. El código debía estar **documentado por completo** (dartdoc en clases, métodos y campos públicos). Además, se debía crear el archivo `IA_USAGE.md` junto al `README.md` para registrar cada interacción con IA.

**Herramienta de IA utilizada.**

• Cursor AI (asistente de código integrado en el IDE, modelo Claude).

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Vamos a crear un juego cumpliendo Patrones de diseño, Clean Architecture y en este momento vamos a crear solo la capa de dominio, el juego se llama Arrow Maze, debe tener al menos estas entidades principales como son
>
> Player  
> board  
> cell  
> level
>
> Asi mismo si tienes otras opciones que pueden ser entidades, crealas para ser revisadas
>
> detalles importantes que debemos tomar en cuenta, se debe generar el codigo documentado por completo y asi mismo en la parte general donde esta el readme.md hay que crear un archivo llamado IA_USAGE.md, donde cada consulta debes agregar:
>
> Tarea o problema abordado.  
> • Herramienta de IA utilizada.  
> • Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).  
> • Resultado obtenido (fragmento de código, diseño, explicación).

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se creó la estructura `lib/domain/` con separación por bounded contexts y documentación dartdoc en toda la API pública.

**Entidades principales solicitadas:**

| Entidad | Ubicación | Rol |
|---------|-----------|-----|
| `Player` | `player/entities/player.dart` | Identidad del jugador |
| `Board` | `board/aggregates/board.dart` | Tablero con celdas y flechas (agregado raíz inicial) |
| `Cell` | `board/entities/cell.dart` | Celda individual del grid |
| `Level` | `level/entities/level.dart` | Definición de nivel con configuración |

**Entidades adicionales propuestas para revisión:**

| Entidad | Rol |
|---------|-----|
| `Arrow` | Flecha con dirección y estado en el tablero |
| `Game` | Sesión de juego activa |
| `PlayerProgress` | Progreso del jugador por nivel |
| `PlayerProfile` | Agregado de perfil y estadísticas |

**Value objects compartidos:** `Identifier`, `Position`, `Direction`, `BoardDimension`, `CellState`, `ArrowState`, `MoveResult`, `LevelConfiguration`, `PlayerStatistics`, `LevelProgress`, entre otros.

**Agregados raíz definidos inicialmente:** `Board`, `Game`, `PlayerProfile`, `PlayerProgress`.

**Servicios de dominio:** `ArrowMovementEngine`, `CollisionValidator`, `RandomBoardGenerator`.

**Factories:** `BoardFactory`, `CellFactory`.

**Eventos de dominio:** `ArrowExtractedEvent`, `ArrowBlockedEvent`, `GameWonEvent`.

**Excepciones:** `DomainException`, `InvalidMoveException`, `CellOccupiedException`.

**Interfaces de repositorio:** `IGameRepository`, `IPlayerProfileRepository`, `IPlayerProgressRepository`.

**Archivos de proyecto:** `pubspec.yaml`, `analysis_options.yaml`, `README.md`, `IA_USAGE.md`, `.gitignore`, `lib/domain/domain.dart` (barrel export).

**Fragmento representativo del agregado `Board` creado en esta consulta:**

```dart
/// Agregado raíz que representa el tablero de juego.
@immutable
class Board {
  Board({
    required this.id,
    required this.dimension,
    required List<Cell> cells,
    required List<Arrow> arrows,
  }) : _cells = List.unmodifiable(cells),
       _arrows = List.unmodifiable(arrows) {
    _validateInvariants();
  }

  bool get isCleared => activeArrows.isEmpty;

  Board placeArrow(Arrow arrow) { /* ... */ }
  Board applyArrowUpdate(Arrow updatedArrow, {bool clearCell = false}) { /* ... */ }
}
```

---

## Consulta #2 — Correcciones de agregados, carga JSON y sistema de estrellas

**Tarea o problema abordado.**

Corregir la arquitectura del dominio: `Board` no debe ser el agregado que coordina el juego; esa responsabilidad corresponde a `Level` (definición del nivel) y `Game` (sesión activa). Los niveles deben cargarse desde **JSON** con campos definidos (`id`, `difficulty`, `board.rows`, `board.cols`, `board.cells[]`, `playerStart`, `parMoves`, `timeLimit`). Implementar derrota al superar `parMoves`, cálculo automático de la ruta más corta y sistema de **estrellas (1–3)** según la cantidad de movimientos usados.

**Herramienta de IA utilizada.**

• Cursor AI (asistente de código integrado en el IDE, modelo Claude).

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> 1) board fue creado con aggregate en el cual el que coordina todo sobre el juego, pero quien realmente realiza eso es Level o en su defecto a mas nivel game, en el cual todos los cambios deberian ser alli
>
> 2) los datos de los level deben ser recibidos de un Json, que debem tener como valores de recepcion los siguentes datos id(string), difficulty(enum), board.rows(integer), board.cols(integer), board.cells[](array), playerStart(Object), parMoves(integer), timeLimit(integer?)
>
> 3) asi mismo, cada nivel debe tener un numero de movimientos para que si se sobrepasa debe dar al jugador el mensaje de que perdio, el mismo debe ser, donde el sistema debe realizar un calculo de la ruta mas corta y le assigna un collection (que serian como estrellas) por haberlo logrado en el menor de intentos posibles, y un promedio donde va disminuyendo la cantidad de estrellas que se otorgan, en este caso se hara con 3 estrellas, con el minimo 3 estrellas y con el maximo sin agotar intentos seria 1 estrella ganada

**Resultado obtenido (fragmento de código, diseño, explicación).**

### Cambios de arquitectura

| Antes (Consulta #1) | Después (Consulta #2) |
|---------------------|----------------------|
| `Board` como agregado raíz | `Board` reclasificado como **entidad** en `board/entities/board.dart` |
| `Level` como entidad simple | `Level` promovido a **agregado raíz** en `level/aggregates/level.dart` |
| `Game` orquestaba parcialmente | `Game` coordina **todas** las mutaciones en runtime |
| `LevelConfiguration` con generación procedural | Carga desde **JSON** con `LevelFactory` |

**Agregados raíz finales:** `Level`, `Game`, `PlayerProfile`, `PlayerProgress`.

### Esquema JSON de niveles

Ejemplo en `docs/levels/example_level.json`:

```json
{
  "id": "level-001",
  "difficulty": "easy",
  "board": {
    "rows": 3,
    "cols": 3,
    "cells": [
      { "row": 0, "col": 0, "direction": "right" },
      { "row": 0, "col": 2, "direction": "down" },
      { "row": 2, "col": 2, "direction": "left" }
    ]
  },
  "playerStart": { "row": 1, "col": 1 },
  "parMoves": 6,
  "timeLimit": 120
}
```

**Archivos nuevos creados:**

- `level/value_objects/level_board_definition.dart` — Parseo del objeto `board`
- `level/value_objects/level_cell_data.dart` — Elementos de `board.cells[]`
- `level/value_objects/player_start.dart` — Objeto `playerStart`
- `level/value_objects/star_rating.dart` — Calificación 1–3 estrellas
- `level/factories/level_factory.dart` — Carga JSON + validación
- `level/services/shortest_path_calculator.dart` — BFS para ruta óptima
- `level/services/star_rating_calculator.dart` — Cálculo de estrellas
- `game/value_objects/game_loss_message.dart` — Mensaje de derrota

**Archivos eliminados:**

- `board/aggregates/board.dart` (movido a `board/entities/`)
- `level/entities/level.dart` (reemplazado por agregado)
- `level/value_objects/level_configuration.dart`

### Sistema de movimientos y estrellas

| Concepto | Comportamiento |
|----------|----------------|
| `optimalMoves` | Calculado al cargar el nivel con `ShortestPathCalculator` (BFS) |
| `parMoves` | Máximo de movimientos; al agotarlos sin ganar → derrota |
| 3 estrellas | Completar en ≤ `optimalMoves` |
| 2 estrellas | Desempeño intermedio (interpolación lineal) |
| 1 estrella | Completar en `parMoves` (límite sin perder) |
| Derrota | `GameLossMessage.movesExceeded`: *"Has superado el número máximo de movimientos permitidos. ¡Has perdido!"* |

### Fragmento de `Game.performMove` (coordinación central):

```dart
if (cleared) {
  final stars = _starRatingCalculator.calculate(
    moveCount: newMoveCount,
    optimalMoves: level.optimalMoves,
    parMoves: level.parMoves,
  );
  return (
    game: copyWith(
      status: GameStatus.won,
      starsEarned: stars,
      finishedAt: DateTime.now().toUtc(),
    ),
    result: moveOutcome.result,
  );
}

if (newMoveCount >= level.parMoves) {
  return (
    game: copyWith(
      status: GameStatus.lost,
      lossMessage: GameLossMessage.movesExceeded,
      finishedAt: DateTime.now().toUtc(),
    ),
    result: moveOutcome.result,
  );
}
```

### Fragmento de `Board` como entidad (estado final):

```dart
/// Entidad que representa el estado del tablero en un momento dado.
/// Las mutaciones durante una partida las coordina el agregado [Game];
/// la definición inicial proviene del agregado [Level].
class Board {
  bool get isCleared => activeArrows.isEmpty;
  Board placeArrow(Arrow arrow) { /* ... */ }
  Board applyArrowUpdate(Arrow updatedArrow, {bool clearCell = false}) { /* ... */ }
}
```

**Otros ajustes:** `GameWonEvent` incluye `starsEarned`; `LevelProgress` y `PlayerProgress.completeLevel()` registran `bestStars`; `README.md` actualizado con arquitectura y esquema JSON.

---

## Consulta #3 — Fusión de dominio Sprint 1 (ramas `Develop` + `Integracion`)

**Tarea o problema abordado.**

Dos compañeros del equipo habían construido, sin coordinarse, el mismo dominio dos veces en ramas distintas: `Develop` (dominio en inglés, más completo, sin dependencia de Flutter) e `Integracion` (dominio en español, más simple, pero con `pubspec.yaml`/`main.dart` de Flutter real). Ninguna de las dos estaba fusionada a `main`. Se necesitaba unificar ambas en una sola rama (`feature/merge-domain-and-shell`), quedándose con el dominio en inglés de `Develop` como base, el "shell" de Flutter de `Integracion`, y portando al inglés los comportamientos que solo existían en la versión en español.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, ejecutado como agente con acceso a la terminal y al sistema de archivos del repositorio.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Avanza con el plan de Sprint 1 aprobado: crear la rama de fusión desde `Develop`, traer el `pubspec.yaml`/`main.dart` de `Integracion`, portar al dominio en inglés los 6 comportamientos que solo existen en `Integracion` (pausa/reanudación, puntaje, reinicio de flecha, resultado "sin flecha", eventos de dominio del tablero, presets de generación por dificultad), comentando cada función en español y dejando pruebas unitarias AAA para cada comportamiento portado.

**Resultado obtenido (fragmento de código, diseño, explicación).**

### Comportamientos portados desde `Integracion` (español) hacia `Develop` (inglés)

| # | Origen (Integracion) | Destino (Develop) | Cambio |
|---|---|---|---|
| 1 | `EstatusJuego.pausado`, `Partida.pausar()/reanudar()` | `GameStatus.paused`, `Game.pause()/resume()` | Nuevo estado de pausa con validación de transición |
| 2 | `EstadoPartida.puntuacion`, `porcentajeCompletado()` | `Game.score`, `Game.completionPercentage()` | +100 puntos por flecha extraída |
| 3 | `Flecha.reiniciar()` | `Arrow.reset()` | Restaura posición original y estado activo |
| 4 | `ResultadoMovimiento.sinFlecha` | `MoveResultType.noArrowAtCell`, `ArrowMovementEngine.attemptMoveAt()` | Responde sin excepción al tocar una celda vacía |
| 5 | `Tablero.consumirEventosDominio()` | `Board.domainEvents`/`withDomainEvent()`/`pullDomainEvents()` | Los eventos `ArrowBlockedEvent`/`ArrowExtractedEvent` (antes código muerto) ahora se emiten y se pueden drenar |
| 6 | `ConfiguracionNivel.desdeDificultad` | `LevelGenerationConfig.fromDifficulty()`, `LevelDifficultyGeneration` (extension) | Presets de dimensión/densidad/semilla por dificultad |

### Ajustes del equipo sobre el resultado de la IA

- El campo `domainEvents` de `Board` se implementó de forma inmutable (no como cola mutable, como en el original en español) para respetar el `@immutable` ya usado en toda la capa de dominio: `withDomainEvent()` retorna una copia con el evento agregado, y `pullDomainEvents()` retorna `(events, board)` en vez de mutar en sitio.
- `LevelGenerationConfig.fromDifficulty()` se dejó como una utilidad separada (`LevelFactory.boardGenerationConfigFor()`) en vez de construir un `Level` completo de forma procedural, porque eso requeriría además derivar un `LevelBoardDefinition` a partir del tablero generado — se consideró fuera del alcance de Sprint 1.
- Se revisaron manualmente todas las referencias de documentación (`[Clase]`) para no dejar enlaces de dartdoc a símbolos no importados en cada archivo.

### Limitación de esta sesión

No se pudo ejecutar `flutter pub get && flutter analyze && flutter test` en el entorno donde se hizo la fusión (no había Flutter/Dart SDK instalado). El código se revisó manualmente contra las convenciones ya usadas en el repo; el equipo debe correr esos comandos localmente antes de abrir el PR para confirmar que compila y que las pruebas nuevas (`test/domain/board/arrow_test.dart`, `test/domain/board/board_events_test.dart`, `test/domain/game/game_test.dart`) pasan.

---
