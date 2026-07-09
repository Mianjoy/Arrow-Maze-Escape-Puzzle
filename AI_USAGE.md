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

## Consulta #6 — Corrección de un bug de lógica de juego detectado al probar la app en navegador

**Tarea o problema abordado.**

Al servir el build web y jugar los 3 niveles, el equipo detectó que un nivel podía "terminarse" con flechas todavía en el tablero. Diagnóstico: eran tres síntomas de una misma causa raíz en el dominio (código heredado de la fusión de la Consulta #3) — el estado `blocked` de una flecha se trataba como si la flecha ya no estuviera en el tablero.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Opus 4.8, agente con acceso a terminal y navegador.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> El front se muestra y se puede interactuar con los 3 niveles, pero tiene errores de lógica: en el nivel 3 el nivel termina cuando aún hay flechas en el tablero. (Además el equipo decidió: un toque a una flecha bloqueada sí debe gastar un movimiento.)

**Resultado obtenido (fragmento de código, diseño, explicación).**

Tres bugs del dominio, misma raíz (`blocked` = "fuera del tablero"), corregidos:
1. `Arrow.isMovable` era `state == active`, así que una flecha bloqueada quedaba **congelada para siempre** (no se podía re-disparar ni después de despejar lo que la bloqueaba). Cambiado a `state != extracted`: el bloqueo es una condición del intento anterior, no una propiedad permanente.
2. `Board.isCleared`/`activeArrows` filtraban por `state == active`, así que **una flecha bloqueada no contaba como presente**: el nivel se declaraba resuelto (o terminaba) con flechas aún en el tablero. Redefinido `activeArrows` como "no extraídas" (que además es lo que decía su propio comentario).
3. `CollisionValidator` usaba `activeArrows`, así que una flecha bloqueada **dejaba de bloquear a otras**; la misma corrección de (2) lo arregla.
- El costo de movimiento de un toque bloqueado se dejó como está (sí cuenta), por decisión explícita del equipo.

**Modificaciones realizadas por el equipo al resultado de la IA:**

- El equipo decidió que un toque bloqueado sí gasta movimiento (en vez de ser gratis), así que solo se corrigió el congelamiento, no el conteo.
- Se actualizó un test que asumía el comportamiento viejo ("re-tocar una flecha bloqueada es no-op") y se agregó una prueba de regresión clave: flecha bloqueada → se despeja el bloqueador → se puede extraer → nivel ganado.
- Verificación: `flutter analyze` sin issues, `flutter test` con 26 tests en verde (el test de assets confirma que los 3 niveles siguen siendo resolubles con la lógica de colisión ya corregida).

**Lecciones aprendidas o limitaciones identificadas:**

- El bug solo se manifestó **jugando la app real en el navegador**, no en los tests que existían: confirma que la prueba manual (pendiente en la Consulta #5) sí aportaba algo que la suite no cubría. Se cerró además con un test de regresión para que no vuelva.
- Un mismo error conceptual ("un estado transitorio se modela como permanente") se propagó a tres lugares (`isMovable`, `isCleared`, colisión); arreglar la definición compartida (`activeArrows`) en vez de parchear cada síntoma resolvió dos de los tres de una sola vez.
- Sigue pendiente la expansión del dominio al formato completo del backend (muros, salida, flechas multi-celda), acordada con el equipo como el siguiente trabajo mayor.

---

## Consulta #7 — Fijar contrato de niveles compartido (Día 1 del plan de integración)

**Tarea o problema abordado.**

Cerrar la **parte 1** del plan de 5 días: acordar y fijar el contrato de niveles entre frontend y backend. Los dos repos usaban JSON incompatibles (frontend: `board.cells` / `parMoves`; backend: `StructuredLevelJsonDto` con `arrows[].head/body`, `exit`, `walls`, `maxMoves`). Sin un contrato único y un adaptador, la integración API (Día 2) quedaba bloqueada.

**Herramienta de IA utilizada.**

- Cursor AI (asistente integrado en el IDE).

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> comienza con la parte 1 del plan "Acordar y fijar el contrato de niveles"
>
> (posteriormente) necesito que comentes todo el codigo para saber que hace cada funcion y actualiza el IA_USAGE.md con los parametros y normas establecidas

**Resultado obtenido (fragmento de código, diseño, explicación).**

### Normas establecidas del contrato (obligatorias para el equipo)

| Norma | Detalle |
|-------|---------|
| **Fuente de verdad** | `BackEnd-ArrowMaze/docs/contract/level.contract.ts` — cualquier cambio empieza ahí y se replica en Dart. |
| **Espejo Dart** | `lib/contract/level_contract.dart` — importable; documentación humana en `docs/contract/README.md`. |
| **Adaptador único** | Solo `lib/interface_adapters/level_dto_mapper.dart` traduce wire → dominio. `lib/domain/` **no** importa el contrato. |
| **JSON legacy** | `assets/levels/level_0X.json` (`board.cells`, `playerStart`, `parMoves`) sigue válido vía `LevelFactory` hasta migrar; niveles nuevos y API usan wire format. |
| **Comentarios** | Español en cada función/método público (dartdoc `///`), como el resto del proyecto. |
| **Commits** | Conventional Commits; actualizar `AI_USAGE.md` en el mismo momento de cada consulta con IA. |
| **Dominio en inglés** | Nombres de clases/campos en inglés; comentarios en español. |

### Mapeo de parámetros wire format → dominio Flutter

| Campo `StructuredLevelJsonDto` | Tipo / valores | Campo dominio | Notas |
|-------------------------------|----------------|---------------|-------|
| `id` | `string` | `Level.id` | Identificador único |
| `levelNumber` | `int` ≥ 1 | `Level.levelNumber` | Orden en progresión |
| `difficulty` | `EASY` \| `MEDIUM` \| `HARD` \| `EXPERT` | `LevelDifficulty` (`easy`…) | Mayúsculas solo en JSON |
| `maxMoves` | `int` > 0 | `Level.parMoves` | Techo antes de perder |
| `maxTimeInSeconds` | `int` | `Level.timeLimit` | Segundos |
| `width` | `int` | `boardDefinition.dimension.columns` | Columnas |
| `height` | `int` | `boardDefinition.dimension.rows` | Filas |
| `exit` | `{ row, col }` | `boardDefinition.exit` + `playerStart` | No hay avatar; `exit` como ancla |
| `walls` | `{ row, col }[]` opcional | `boardDefinition.walls` | `CellState.wall` |
| `arrows` | ver abajo | `boardDefinition.arrowPlacements` | Multi-celda |

**Objeto `arrows[]`:**

| Campo | Tipo | Dominio |
|-------|------|---------|
| `id` | `string` | `LevelArrowPlacement.id` |
| `direction` | `UP` \| `DOWN` \| `LEFT` \| `RIGHT` | `Direction` |
| `head` | `{ row, col }` | `LevelArrowPlacement.head` |
| `body` | `{ row, col }[]` | `LevelArrowPlacement.body` |

### Archivos creados o modificados

| Archivo | Rol |
|---------|-----|
| `lib/contract/level_contract.dart` | DTOs espejo del TypeScript |
| `lib/interface_adapters/level_dto_mapper.dart` | Adaptador wire → `Level` |
| `docs/contract/README.md` | Decisión y tabla de mapeo |
| `docs/levels/simple-1.json` | Nivel canónico (mismo que backend) |
| `lib/domain/level/value_objects/level_arrow_placement.dart` | VO de flecha multi-celda |
| `test/interface_adapters/level_dto_mapper_test.dart` | Tests de parseo y mapeo |
| Dominio extendido | `Arrow.body`, `CellState.wall`, `Board.placeArrowSegments`, etc. |

**Fragmento del adaptador:**

```dart
class LevelDtoMapper {
  Level fromDto(StructuredLevelJsonDto dto) {
    final provisional = _toProvisionalLevel(dto);
    final board = provisional.buildInitialBoard(boardFactory: _boardFactory);
    final optimalMoves = _shortestPathCalculator.calculateMinimumMoves(board);
    // valida solvabilidad y optimalMoves <= dto.maxMoves
    return Level(/* ... */);
  }
}
```

**Modificaciones realizadas por el equipo al resultado de la IA:**

- (Pendiente de revisión del equipo tras merge.)

**Lecciones aprendidas o limitaciones identificadas:**

- El backend valida *jugabilidad* (`LevelSolvabilityValidator`); el frontend además exige `optimalMoves <= maxMoves` para que el par sea alcanzable con las reglas de estrellas — un `maxMoves` bajo puede hacer fallar `fromDto` aunque el nivel sea “jugable” en más movimientos.
- Los 3 assets legacy no se migraron aún; `JsonAssetLevelRepository` actúa como respaldo offline vía `FallbackLevelRepository`.
- Integración remota completada en Consulta #8 (`RemoteLevelRepository` + `AppContainer`).

---

## Consulta #8 — Integración remota de catálogo de niveles (Día 2 frontend)

**Tarea o problema abordado.**

Cerrar la segunda mitad del **Día 2** del plan de integración (5 días): conectar la app Flutter al backend operativo (seed + JWT ya desplegado en `BackEnd-ArrowMaze`) mediante un repositorio HTTP que consuma `GET /levels` y `GET /levels/:id`, traduzca `StructuredLevelJsonDto` a dominio con `LevelDtoMapper` y sustituya `JsonAssetLevelRepository` como fuente principal en el composition root.

**Herramienta de IA utilizada.**

- Cursor AI (asistente integrado en el IDE).

**Prompt o instrucción proporcionada.**

> Implementar el bloque **RemoteLevelRepository + conectar app** del plan crítico: cliente HTTP contra los endpoints públicos de niveles, implementación de `ILevelRepository` remota con `LevelDtoMapper`, wiring en `AppContainer` (composition root), tests con `MockClient`, comentarios dartdoc en español por función, y registro en `AI_USAGE.md` con redacción técnica acorde al estándar del repositorio.

**Resultado obtenido.**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Config API | `lib/infrastructure/http/api_config.dart` | URL base (`API_BASE_URL` vía `--dart-define`, default `localhost:3000`) |
| Cliente HTTP | `lib/infrastructure/http/level_api_client.dart` | `GET /levels`, `GET /levels/:id`, parseo JSON y errores de red |
| Repositorio remoto | `lib/infrastructure/level/remote_level_repository.dart` | `ILevelRepository` + caché en memoria + `LevelDtoMapper` |
| Respaldo offline | `lib/infrastructure/level/fallback_level_repository.dart` | Decorador: remoto → assets si la API falla |
| Excepción infra | `lib/infrastructure/level/level_repository_exception.dart` | Errores HTTP/red sin contaminar el dominio |
| Composition root | `lib/main.dart` → `AppContainer` | Cadena remota + fallback por defecto |
| Tests | `test/infrastructure/level/*` | Mock HTTP, orden por `levelNumber`, 404, fallback |

**Flujo de datos.**

```
LevelSelectScreen → LoadLevelsUseCase → ILevelRepository
  → RemoteLevelRepository → LevelApiClient (GET /levels)
  → LevelDtoMapper.fromJson() → List<Level>
```

**Configuración de entorno.**

```bash
# Web / desktop (backend local)
flutter run -d chrome

# Emulador Android (host loopback)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Backend debe estar en ejecución con seed
cd BackEnd-ArrowMaze && npm run dev
```

**Modificaciones realizadas por el equipo al resultado de la IA.**

- (Pendiente de revisión tras merge.)

**Lecciones aprendidas o limitaciones identificadas.**

- `FallbackLevelRepository` evita pantalla en blanco sin backend, pero puede ocultar fallos de integración si no se prueba explícitamente contra la API.
- El mapper del frontend exige `optimalMoves <= maxMoves`; los niveles del seed deben usar `maxMoves` holgado (p. ej. `simple-1` con 20 en backend vs 5 en el JSON canónico de docs).
- Siguiente paso del plan (Día 4): login/registro + `POST /progress/sync` al ganar.

---

## Consulta #10 — Suite E2E jugable del catálogo remoto (Día 3 frontend)

**Tarea o problema abordado.**

Cerrar el entregable **“Prueba E2E jugable”** del Día 3: demostrar con tests automatizados y guía operativa que el flujo **seed (15 niveles) → `GET /levels` → `RemoteLevelRepository` → selección → partida → victoria/derrota** funciona sin depender de assets legacy.

**Herramienta de IA utilizada.**

- Cursor AI (asistente integrado en el IDE).

**Prompt o instrucción proporcionada.**

> Implementar la validación E2E del bloque Día 3 en `Arrow-Maze-Escape-Puzzle`: suite de tests con catálogo remoto simulado (15 niveles), verificación de mapeo wire-format y jugabilidad (victoria en `level-02`, derrota por `parMoves`, flujo UI lista→juego), flag `ASSET_FALLBACK` para pruebas manuales, documentación en `docs/e2e/README.md`, comentarios dartdoc en español y registro técnico en `AI_USAGE.md`.

**Resultado obtenido.**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Fixture seed | `test/e2e/support/seed_catalog_fixture.dart` | Espejo de 15 niveles del backend |
| Fábrica E2E | `test/e2e/support/e2e_app_factory.dart` | `AppContainer` + `MockHttpClient`, `fallbackToAssets: false` |
| Helper jugabilidad | `test/e2e/support/playable_level_helper.dart` | Mapeo, inicio de partida, solver greedy, conteo de muros |
| Mock HTTP compartido | `test/support/mock_http_client.dart` | Reutilizado por tests de infra y E2E |
| Tests catálogo | `test/e2e/remote_catalog_e2e_test.dart` | 15 niveles, orden, mapper |
| Tests dominio | `test/e2e/wire_format_playability_e2e_test.dart` | Inicio de partida, win/lose wire-format |
| Tests UI | `test/e2e/playable_flow_e2e_test.dart` | Lista remota, victoria `level-02`, derrota `level-09` |
| Flag manual | `lib/main.dart` | `--dart-define=ASSET_FALLBACK=false` |
| Guía | `docs/e2e/README.md` | Procedimiento CI + manual con backend real |

**Ejecución.**

```bash
flutter test test/e2e
flutter run --dart-define=ASSET_FALLBACK=false   # manual contra npm run dev
```

**Modificaciones realizadas por el equipo al resultado de la IA.**

- (Pendiente de revisión tras merge.)

**Lecciones aprendidas o limitaciones identificadas.**

- Los tests E2E de UI usan HTTP simulado (no requieren backend en CI); la prueba manual con backend real sigue siendo necesaria para CORS/red en dispositivos físicos.
- El solver greedy no demuestra solvabilidad óptima de todos los niveles; solo verifica un subconjunto (`level-08`, `level-15`) además del tutorial `level-02`.

---

## Consulta #11 — Verificación integral del sistema (Día 3 — ejecución E2E)

**Tarea o problema abordado.**

Ejecutar la **prueba de sistema completa** del plan de integración: correr la suite automatizada de Flutter (incluido `test/e2e`), validar la integración con el catálogo remoto de 15 niveles y corregir los defectos que impedían el paso en verde de `flutter test`, en coordinación con la verificación del backend (`127/127` tests, API con 15 niveles).

**Herramienta de IA utilizada.**

- Cursor AI (asistente integrado en el IDE).

**Prompt o instrucción proporcionada.**

> Ejecutar la verificación integral del sistema Arrow Maze: validar backend (`npm test`, `GET /levels` con 15 entradas) y frontend (`flutter analyze`, `flutter test`, suite `test/e2e`); corregir los fallos detectados durante la ejecución; documentar parámetros, resultados y lecciones en `AI_USAGE.md` con redacción técnica profesional.

**Parámetros y comandos de verificación.**

| Capa | Comando | Criterio de éxito |
|------|---------|-------------------|
| Frontend — análisis | `flutter analyze` | Sin issues |
| Frontend — tests completos | `flutter test` | 49/49 passed |
| Frontend — E2E | `flutter test test/e2e` | 11/11 passed |
| Integración manual | `flutter run --dart-define=ASSET_FALLBACK=false` + `npm run dev` | Lista de 15 niveles remotos |
| Backend (referencia cruzada) | `npm test` + `curl /levels` | 127 tests, array length 15 |

**Normas de verificación E2E (obligatorias).**

| Norma | Detalle |
|-------|---------|
| **Sin fallback a assets** | Tests E2E usan `E2eAppFactory` con `fallbackToAssets: false` |
| **Fixture alineado al backend** | `SeedCatalogFixture` espeja `LEVEL_SEED_CATALOG` (15 ids) |
| **Victoria mínima** | `level-02`: un disparo → diálogo `Level cleared!` |
| **Derrota por par** | `level-09`: agotar `parMoves` → diálogo `Level failed` |
| **ListView virtualizado** | Scroll con `scrollUntilVisible` antes de assert/tap en niveles 9+ |

**Resultado obtenido (ejecución real).**

| Métrica | Valor final |
|---------|-------------|
| `flutter analyze` | **No issues found** |
| Tests totales | **49 passed**, 0 failed |
| Suite `test/e2e` | **11 passed** (catálogo, dominio, UI) |
| Backend cruzado | `GET /levels` → **15** niveles |

**Correcciones aplicadas durante la verificación.**

| Defecto detectado | Archivo | Corrección |
|-------------------|---------|------------|
| `_requireInt` no visible en `CellPositionDto` | `level_contract.dart` | Función top-level `_requireInt` compartida |
| Assert `column >= 0` al salir del tablero | `collision_validator.dart` | Validar límites **antes** de instanciar `Position` |
| `levelNumber` nullable en ordenación | `remote_level_repository.dart` | `(a.levelNumber ?? 0).compareTo(...)` |
| UI E2E: `level-15` / `level-09` no visibles | `playable_flow_e2e_test.dart` | `scrollUntilVisible` + tests separados lista / juego |

**Fragmento de corrección (`CollisionValidator`):**

```dart
final nextRow = current.row + arrow.direction.deltaRow;
final nextCol = current.column + arrow.direction.deltaColumn;
if (nextRow < 0 || nextCol < 0 ||
    nextRow >= board.dimension.rows ||
    nextCol >= board.dimension.columns) {
  return null; // trayectoria libre hacia el exterior
}
final next = Position(row: nextRow, column: nextCol);
```

**Modificaciones realizadas por el equipo al resultado de la IA.**

- (Pendiente de revisión tras merge.)

**Lecciones aprendidas o limitaciones identificadas.**

- `Position` con asserts no negativos exige comprobar límites del tablero **antes** de construir coordenadas intermedias; `nextPositionFrom` fallaba en flechas que salen por el borde (p. ej. `simple-1`).
- `ListView.builder` no renderiza todos los `ListTile` a la vez: contar widgets en pantalla ≠ cantidad de niveles cargados; usar scroll o asserts sobre el repositorio.
- La suite E2E con HTTP mock valida la cadena completa sin backend en CI; la demo manual con `ASSET_FALLBACK=false` sigue siendo el criterio de integración real.

---

## Consulta #12 — Autenticación, progreso y leaderboard (Día 4 frontend)

**Tarea o problema abordado.**

Implementar el **Día 4** del plan de integración en Flutter: flujo de **registro e inicio de sesión** contra el backend, **persistencia del JWT**, **sincronización de progreso** al completar un nivel (`POST /progress/sync`) y **consulta de ranking** por nivel (`GET /leaderboard/:levelId`), con comentarios explicativos en todo el código nuevo y registro en `AI_USAGE.md`.

**Herramienta de IA utilizada.**

- Cursor AI (asistente integrado en el IDE).

**Prompt o instrucción proporcionada.**

> Implementar el bloque Día 4 (autenticación, progreso y leaderboard) en `Arrow-Maze-Escape-Puzzle`: pantallas de login/registro, almacenamiento de JWT, sincronización automática al ganar un nivel, vista de leaderboard, integración en `AppContainer`, tests automatizados y documentación dartdoc en español; actualizar `AI_USAGE.md` con redacción técnica profesional.

**Resultado obtenido.**

| Capa | Archivos principales | Responsabilidad |
|------|---------------------|-----------------|
| Aplicación | `auth_session.dart`, `leaderboard_entry.dart`, `i_token_storage.dart` | Modelos y puerto de persistencia de sesión |
| Casos de uso | `login_user_use_case.dart`, `register_user_use_case.dart`, `logout_user_use_case.dart`, `restore_auth_session_use_case.dart`, `record_victory_use_case.dart`, `get_leaderboard_use_case.dart` | Orquestación auth, sync y ranking |
| Infraestructura HTTP | `auth_api_client.dart`, `progress_api_client.dart`, `leaderboard_api_client.dart`, `api_exception.dart` | Clientes REST alineados al contrato del backend |
| Almacenamiento | `shared_preferences_token_storage.dart`, `in_memory_token_storage.dart` | JWT en dispositivo / memoria (tests) |
| Presentación | `auth_session_controller.dart`, `login_screen.dart`, `register_screen.dart`, `leaderboard_screen.dart` | UI de auth y ranking |
| Integración | `main.dart`, `game_controller.dart`, `game_screen.dart`, `level_select_screen.dart` | Rutas, sync al ganar, logout |
| Dominio | `game.dart` (`elapsedSeconds`) | Métrica para `timeInSeconds` en sync |
| Tests | `auth_api_client_test.dart`, `record_victory_use_case_test.dart`, `test_auth_session.dart` | Cobertura de clientes y victoria |
| E2E | `e2e_app_factory.dart` | Mock de auth/progress/leaderboard + sesión precargada |

**Flujo implementado.**

```text
/login o /register → JWT en SharedPreferences
       ↓
/ (LevelSelect) → /game → victoria → RecordVictoryUseCase
       ↓                              ↓
logout                         POST /progress/sync (Bearer)
       ↓
/leaderboard/:levelId ← GET /leaderboard/:levelId
```

**Dependencia añadida.**

- `shared_preferences: ^2.3.3` — persistencia local del token JWT.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- (Pendiente de revisión tras merge.)

**Lecciones aprendidas o limitaciones identificadas.**

- El registro en el backend no devuelve JWT; el caso de uso encadena `register` + `login` automáticamente.
- La sincronización de progreso ocurre antes de mostrar el diálogo de victoria para reflejar éxito/error de sync.
- Los tests E2E precargan sesión (`E2eAppFactory.e2eSession`) para no romper la suite sin pantalla de login.
- Siguiente paso del plan (Día 5 / cierre): pulir UX (sesión expirada, errores de red), prueba en emulador Android y preparación de entrega.

---
