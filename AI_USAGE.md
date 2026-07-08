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

El equipo habia realizado partes del proyecto y se creó el mismo dominio dos veces en ramas distintas: `Develop` (dominio en inglés, más completo, sin dependencia de Flutter) e `Integracion` (dominio en español, más simple, pero con `pubspec.yaml`/`main.dart` de Flutter real). Ninguna de las dos estaba fusionada a `main`. Se necesitaba unificar ambas en una sola rama (`feature/merge-domain-and-shell`), quedándose con el dominio en inglés de `Develop` como base, el "shell" de Flutter de `Integracion`, y portando al inglés los comportamientos que solo existían en la versión en español.

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

## Consulta #4 — Verificación real con Flutter SDK y scaffold de plataformas

**Tarea o problema abordado.**

Cerrar la limitación de la Consulta #3: instalar Flutter de verdad y correr `pub get`/`analyze`/`test`/`build` sobre `feature/merge-domain-and-shell` para confirmar que la fusión de dominio realmente compila y corre, no solo que se revisó a mano.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, ejecutado como agente con acceso a la terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Instala Flutter en este entorno y corre la verificación real (pub get, analyze, test, build) sobre la rama fusionada antes de abrir el PR.

**Resultado obtenido (fragmento de código, diseño, explicación).**

- Se instaló Flutter 3.44.5 (stable) vía Homebrew (`brew install --cask flutter`).
- `flutter pub get`: resolvió las 60 dependencias sin problema.
- `flutter analyze` (primera corrida) encontró 5 problemas reales que la revisión manual no había detectado:
  - 2 imports sin usar (`arrow_movement_engine.dart` importaba `Arrow`, `random_board_generator.dart` importaba `Position`, ninguno de los dos se referenciaba por nombre en el archivo, solo vía variables con tipo inferido).
  - `library domain;` marcado como innecesario por el linter (`unnecessary_library_name`).
  - 2 casos de documentación faltante en `ArrowMazeApp` (`lib/main.dart`, heredado de `Integracion`), exigidos por la regla `public_member_api_docs` ya configurada en `analysis_options.yaml`.
- **Hallazgo más importante**: el proyecto fusionado no tenía carpetas de plataforma (`android/`, `ios/`, `web/`, etc.) — nunca se había corrido `flutter create` sobre él. `Integracion` solo aportó `pubspec.yaml`/`main.dart` con la dependencia de Flutter declarada, pero sin el scaffold real, así que `flutter run`/`flutter build` no tenían dónde ejecutar.

**Modificaciones realizadas por el equipo al resultado de la IA:**

- Se corrigieron los 5 hallazgos de `flutter analyze` (imports, nombre de library, documentación faltante) hasta dejarlo en "No issues found!".
- Se corrió `flutter create .` para generar android/ios/web/linux/macos/windows sin tocar el dominio ya fusionado; se confirmó que no sobrescribió `pubspec.yaml` ni `lib/main.dart` existentes.
- Se eliminó `test/widget_test.dart` (el test por defecto del template, que referenciaba un widget `MyApp` inexistente en este proyecto).
- Verificación final: `flutter analyze` sin problemas, `flutter test` con los 12 tests en verde, `flutter build web` exitoso.

**Lecciones aprendidas o limitaciones identificadas:**

- Una revisión manual de código, por cuidadosa que sea, no sustituye correr las herramientas reales: 5 de 5 hallazgos de `flutter analyze` no se habían detectado a mano en la Consulta #3.
- Que un `pubspec.yaml` declare la dependencia de Flutter no implica que el proyecto tenga scaffold de plataforma; hay que confirmarlo explícitamente con `flutter run`/`flutter build`, no asumirlo.
- Solo se generó el scaffold de plataformas (no se decidió aún cuáles se usarán en producción — Android/iOS/Web); esa decisión y la configuración específica de cada una quedan para cuando el equipo lo defina.

---

## Consulta #5 — Primera versión jugable: capas de aplicación, infraestructura y presentación

**Tarea o problema abordado.**

Hasta ahora el repo solo tenía la capa de dominio y un `main.dart` de marcador de posición (un `Scaffold` con texto estático); no había nada jugable. Este era el mayor riesgo del proyecto frente a la rúbrica (criterio "Funcionalidad del Juego", 4 de 20 pts — el ítem individual de mayor peso — en ~0%). El objetivo fue una primera rebanada jugable de punta a punta: composition root, pantalla de selección de nivel, y el motor de juego básico (renderizar el tablero, tocar para disparar una flecha, detectar victoria), reutilizando el dominio Dart tal cual.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Opus 4.8 (parte de la sesión con Sonnet 5), ejecutado como agente con acceso a la terminal y al sistema de archivos, en modo de planificación con aprobación explícita del plan antes de implementar.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Avancemos con el frontend Flutter. Empezar por el composition root + la pantalla de selección de nivel + el motor de juego básico (tablero + disparo de flechas), reutilizando el dominio Dart existente, y dejando pantallas de inicio/audio/i18n para después.

**Resultado obtenido (fragmento de código, diseño, explicación).**

- Nuevo puerto de dominio `lib/domain/repositories/i_level_repository.dart` (`ILevelRepository`), que faltaba (los niveles solo se cargaban ad hoc vía `LevelFactory.fromJson`).
- Capa de aplicación nueva (`lib/application/use_cases/`): `LoadLevelsUseCase`, `StartGameUseCase`, `FireArrowUseCase` — cada uno dependiendo solo de puertos (DIP). `FireArrowUseCase` resuelve el `arrowId` de la celda tocada y trata tanto "celda vacía" como "flecha ya bloqueada/no movible" como no-op, para que la excepción `InvalidMoveException` del dominio no llegue a la UI.
- Capa de infraestructura nueva (`lib/infrastructure/`): `JsonAssetLevelRepository` (carga niveles desde assets JSON vía `rootBundle` + `LevelFactory`), e implementaciones en memoria de `IGameRepository`/`IPlayerProgressRepository`.
- 3 niveles de ejemplo en `assets/levels/` (esquema JSON que el dominio ya parsea; NO es el requisito de 15 niveles, solo para ejercitar el pipeline).
- Capa de presentación nueva (`lib/presentation/`): `LevelSelectController`/`LevelSelectScreen` y `GameController`/`GameScreen`/`BoardView`, usando `ChangeNotifier` + `ListenableBuilder` + `Navigator` (sin dependencias nuevas de gestión de estado, decisión explícita del equipo).
- `lib/main.dart` reescrito como composition root (`AppContainer`) con rutas nombradas, mismo rol que `container.ts` en el backend.
- Tests nuevos: unitarios de los 3 casos de uso (`package:test`, patrón AAA, con fakes de repositorios), widget tests de ambas pantallas (`flutter_test` — los primeros del repo), y un test que valida que los 3 JSON de niveles reales parsean y son resolubles vía `LevelFactory` (leyéndolos con `dart:io`, cerrando el hueco de que los widget tests usan un `FakeLevelRepository`).

**Modificaciones realizadas por el equipo al resultado de la IA:**

- Se instaló Flutter en el entorno Windows del equipo (3.35.6 stable, vs. el 3.44.5 vía Homebrew de la Consulta #4 que era el entorno macOS de otro integrante); la descarga desde Google Storage fue muy lenta y se diagnosticó que no era problema de la red del equipo sino del enrutamiento a ese servidor.
- Igual que en la Consulta #4, `flutter analyze` volvió a atrapar lo que la revisión a mano no vio: 34 avisos de `public_member_api_docs` (documentación faltante en miembros públicos de las capas nuevas), que se corrigieron hasta dejar "No issues found!".
- Verificación real completa: `flutter analyze` sin issues, `flutter test` con 25 tests en verde (13 de dominio previos + 12 nuevos), y `flutter build web` exitoso.

**Lecciones aprendidas o limitaciones identificadas:**

- Se confirma por segunda consulta consecutiva (ver Consulta #4) que correr `flutter analyze` de verdad atrapa problemas reales invisibles a la revisión manual; el equipo trata "escribí el código" y "el código pasa analyze/test" como dos hitos distintos.
- Los widget tests con repositorios fake no ejercitan la carga real de assets; se agregó un test dedicado que corre los JSON reales por `LevelFactory` para no dejar ese camino sin cubrir.
- Alcance deliberadamente acotado: quedan pendientes como follow-up las pantallas de inicio/ajustes, audio, i18n, persistencia de progreso/bloqueo de niveles, los 15 niveles requeridos (hoy hay 3), y el adaptador que consuma el contrato `StructuredLevelJsonDto` del backend real (el esquema JSON local del dominio y el contrato del backend aún difieren; ese puente es trabajo aparte).
- Falta la prueba manual en navegador (click-through en vivo): el build web compila y los widget tests manejan las pantallas reales, pero no se hizo una corrida interactiva en Chrome en esta sesión.

---
