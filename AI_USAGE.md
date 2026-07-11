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

Se corrió `flutter analyze`/`flutter test` de verdad tras el merge (no solo revisión manual) y aparecieron 6 problemas reales, corregidos con Claude Code:

- `game_controller.dart`: `GameController extends ChangeNotifier` sin importar `package:flutter/foundation.dart` — provocaba 5 errores en cascada (`notifyListeners` indefinido, `extends_non_class`). Se agregó el import faltante.
- `main.dart`: `recordVictoryUseCase` declarado `final` pero asignado en el cuerpo del constructor (depende de `progressApiClient`, ensamblado ahí mismo) — eso exige `late final`, no `final`. Corregido.
- 2 imports sin usar (`level_select_screen.dart`, `auth_api_client_test.dart`) y 1 doc faltante (`shared_preferences_token_storage.dart`, regla `public_member_api_docs`).
- **Bug real en el helper de tests `test/support/mock_http_client.dart`**: `send()` reconstruía un `http.Request` vacío en vez de reenviar la petición real, descartando headers y body. Esto hacía fallar en silencio cualquier test que verificara headers/body; se detectó porque `record_victory_use_case_test.dart` esperaba `Authorization: Bearer tok` y recibía `null`. Se corrigió para reenviar la petición original.

Con estos 6 arreglos: `flutter analyze` → *No issues found!*, `flutter test` → **52/52 en verde**.

**Lecciones aprendidas o limitaciones identificadas.**

- El registro en el backend no devuelve JWT; el caso de uso encadena `register` + `login` automáticamente.
- La sincronización de progreso ocurre antes de mostrar el diálogo de victoria para reflejar éxito/error de sync.
- Los tests E2E precargan sesión (`E2eAppFactory.e2eSession`) para no romper la suite sin pantalla de login.
- Un helper de test mal implementado (`MockHttpClient`) puede enmascarar bugs reales en el código de producción durante meses si ningún test llega a verificar headers/body — vale la pena revisar los helpers compartidos de tests con el mismo rigor que el código de producción.
- Siguiente paso del plan (Día 5 / cierre): pulir UX (sesión expirada, errores de red), prueba en emulador Android y preparación de entrega.

---

## Consulta #13 — Funcionalidad mínima del enunciado académico (PDF)

**Tarea o problema abordado.**

Implementar los requisitos **críticos de funcionalidad mínima** del proyecto semestral (sección 5.1 del enunciado): pantalla de inicio y ajustes, i18n (es/en), audio con mute, persistencia local de progreso, selección de niveles con bloqueos, pantallas dedicadas de victoria/derrota con siguiente nivel, y documentación en `AI_USAGE.md`.

**Herramienta de IA utilizada.**

- Cursor AI (asistente integrado en el IDE).

**Prompt o instrucción proporcionada.**

> Implementar la funcionalidad mínima crítica del enunciado académico en `Arrow-Maze-Escape-Puzzle`: pantalla de inicio y ajustes, internacionalización español/inglés, efectos de sonido y música con opción de silenciar, persistencia local del progreso del jugador, indicadores de niveles bloqueados en la selección, pantallas dedicadas de victoria y derrota con navegación al siguiente nivel; documentar el código con comentarios explicativos y registrar la consulta en `AI_USAGE.md` con redacción técnica profesional.

**Resultado obtenido.**

| Entregable PDF | Implementación |
|----------------|----------------|
| Pantalla de inicio | `HomeScreen` — `/home` con Jugar y Ajustes |
| Ajustes (mute + idioma) | `SettingsScreen` + `SharedPreferencesAppSettings` |
| i18n es/en | `lib/l10n/app_strings.dart` + `AppStringsScope` |
| Audio + mute | `AppAudioService` (`SystemSound` + `audioplayers` opcional BGM) |
| Persistencia local progreso | `SharedPreferencesPlayerProgressRepository` + `PlayerProgressJsonMapper` |
| Niveles bloqueados / progreso | `EnsureInitialProgressUseCase`, `LevelSelectController` |
| Pantalla victoria + siguiente nivel | `VictoryScreen` + `RecordVictoryResult.nextLevel` |
| Pantalla derrota + reintentar | `DefeatScreen` |

**Archivos principales.**

| Capa | Archivos |
|------|----------|
| L10n | `app_strings.dart` |
| Settings/Audio | `shared_preferences_app_settings.dart`, `app_audio_service.dart` |
| Progreso | `shared_preferences_player_progress_repository.dart`, `player_progress_json_mapper.dart` |
| Casos de uso | `ensure_initial_progress_use_case.dart`, `get_player_progress_use_case.dart` |
| UI | `home_screen.dart`, `settings_screen.dart`, `victory_screen.dart`, `defeat_screen.dart` |
| Tests | `player_progress_json_mapper_test.dart`, actualización E2E/widget |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- (Pendiente de revisión tras merge.)

**Lecciones aprendidas o limitaciones identificadas.**

- La música de fondo requiere `assets/audio/background.mp3`; sin el archivo, los efectos usan `SystemSound` y la app no falla.
- El release APK para GitHub Releases sigue siendo un paso manual del equipo.
- Siguiente paso: diagrama de clases, README actualizado y build Android para entrega formal.

---

## Consulta #14 — Verificación end-to-end real (backend + frontend en vivo) y 4 bugs de arranque/navegación

**Tarea o problema abordado.**

Correr ambos repos juntos de verdad (backend Express real en `localhost:3000` con los 15 niveles sembrados, frontend Flutter Web real apuntando a él, no assets locales) para confirmar que la integración de las últimas consultas funciona jugando en un navegador real, no solo con `flutter test`/`npm test` en verde. Al hacerlo aparecieron 4 bugs reales que ningún test detectaba, todos de "arranque/plomería", no de reglas de juego.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5 / Opus 4.8 según el tramo de la sesión, agente con acceso a terminal y navegador.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Necesito probar el funcionamiento del proyecto, por lo que necesito que pongas a funcionar ambos repositorios para verificar su funcionamiento, y por favor, que sean las ramas con los cambios más recientes.

Seguido de reportes directos del equipo mientras probaba en el navegador ("no carga nada, se queda la pantalla en blanco", "se pierden los datos que tenía la aplicación anteriormente (los usuarios creados)", "al presionar back to the levels la pantalla queda en blanco").

**Resultado obtenido (fragmento de código, diseño, explicación).**

Cuatro bugs reales encontrados y corregidos, todos detectados solo al ejecutar la app real (no por `flutter analyze`/`flutter test`, que ya estaban en verde antes de esta sesión):

1. **`lib/l10n/app_strings.dart`**: `AppStrings` (clase abstracta base) no tenía constructor `const`, así que `AppStringsEn`/`AppStringsEs` no podían serlo tampoco — error de compilación real (`A constant constructor can't call a non-constant super constructor`), la app no compilaba en absoluto. Se agregó `const AppStrings();`.
2. **`lib/main.dart`, `AppContainer`**: dentro del cuerpo del constructor, `audioService = audioService ?? AppAudioService(...)` reasignaba el **parámetro local** (que sombrea al campo del mismo nombre), no el campo `late final audioService` de la clase — el campo nunca se inicializaba, y el primer acceso a `container.audioService` lanzaba `LateInitializationError`, dejando la app en pantalla blanca. Se corrigió a `this.audioService = ...`.
3. **`lib/main.dart`, `_onGenerateRoute`**: ninguna llamada a `MaterialPageRoute(...)` pasaba `settings: settings`, así que `route.settings.name` era siempre `null` para toda ruta creada. El botón "Back to Levels" (`popUntil((route) => route.settings.name == '/levels')`) nunca encontraba una coincidencia y vaciaba toda la pila de navegación → pantalla en blanco permanente al volver de victoria/derrota. Se agregó `settings: settings` a las 8 rutas.
4. **`lib/main.dart`, `AppContainer.initialize()`**: `await audioService.startBackgroundMusic()` bloqueaba el arranque completo de la app. En Flutter Web, el navegador bloquea `AudioContext` hasta un gesto real del usuario (política de autoplay), así que ese `Future` puede no resolver nunca hasta el primer clic — como `initialize()` se espera antes de `runApp()` en `main()`, la app **nunca llegaba a renderizarse**, pantalla en blanco indefinida. Se cambió a `unawaited(audioService.startBackgroundMusic())`.

Efecto colateral detectado al agregar el archivo de audio real (`assets/audio/background.mp3`, compartido por el equipo): el bug #4 solo se manifestaba con el asset presente (antes, `rootBundle.load` fallaba rápido y el `await` se resolvía enseguida) — confirma que un bug de bloqueo async puede quedar oculto mientras la ruta feliz nunca se ejercita.

Además, al correr `flutter test` completo antes de fusionar, aparecieron 4 fallas en tests ya existentes del equipo (no relacionadas a los bugs de arriba): 3 en `test/e2e/playable_flow_e2e_test.dart` y 1 en `test/presentation/game/game_screen_test.dart`, todas por la misma causa — `AppStringsScope` envolvía solo `home:` en vez del `MaterialApp` completo, así que las pantallas alcanzadas por rutas empujadas después (`/victory`, `/defeat`) no heredaban el scope. Se corrigió la estructura de wrapping en ambos archivos de test (mismo patrón que en `main.dart`), se agregó la ruta `/defeat` faltante en el helper E2E, y se reemplazaron aserciones de texto obsoletas (`'Level cleared!'`, `'Level failed'`, restos del diálogo previo a las pantallas dedicadas) por `find.byType(VictoryScreen)`/`find.byType(DefeatScreen)`, más robustas ante cambios de copy/locale.

**Modificaciones realizadas por el equipo al resultado de la IA:**

- Se explicó (no se "arregló" como bug) la pérdida de usuarios/progreso entre reinicios del backend: es comportamiento esperado de `InMemory*Repository` sin base de datos real todavía — pendiente conocido, no regresión de esta sesión.
- El equipo compartió el archivo de audio real (`DTMF8B.mp3`) para reemplazar el placeholder; se copió a `assets/audio/background.mp3`.
- Se usó `flutter build web` + servidor estático (`python -m http.server`) en vez de `flutter run -d web-server` para las verificaciones manuales, tras un problema de caché del compilador DDC (`Library not defined: org-dartlang-app:/web_entrypoint.dart`) al mezclar peticiones automatizadas (`curl`) con el servidor de desarrollo con recarga en caliente.

**Lecciones aprendidas o limitaciones identificadas:**

- Los 4 bugs de arranque eran invisibles a `flutter analyze`/`flutter test` (ambos en verde) porque son errores de **composición en tiempo de ejecución** (sombra de nombres, orden de `await`, wiring de `settings`), no errores de tipos ni de lógica de dominio — solo aparecen al ejecutar la app real de punta a punta. Confirma, por tercera vez en este proyecto (ver Consultas #4 y #5), que "los tests pasan" y "la app funciona jugándola" son dos verificaciones distintas y ninguna sustituye a la otra.
- Un bug de bloqueo asíncrono (#4) puede permanecer dormido mientras la rama de código que lo dispara nunca se alcanza en la práctica (aquí, mientras no había archivo de audio real, el `await` fallaba rápido); agregar un asset real destapó un bug preexistente en la plomería de inicialización.
- La política de autoplay de audio en navegadores es un caso recurrente de "funciona en desarrollo local sin pensarlo, rompe la app en web" — cualquier inicialización que dependa de una API sujeta a gesto del usuario no debe bloquear el arranque de la UI.

---

## Consulta #15 — CI del PR hacia `main` en rojo por deuda de lint preexistente (sesión autónoma)

**Tarea o problema abordado.**

Al abrir el Pull Request de este repo hacia `main` (consolidando todo el trabajo del proyecto), el check de CI (`flutter analyze` + `flutter test`) falló con 65 issues — deuda de lint acumulada del equipo (imports sin usar/innecesarios, documentación pública faltante) que `flutter analyze` local ya había señalado antes en este mismo repo (ver Consultas #4 y #5) pero que no se había terminado de limpiar, más 4 avisos de deprecación real del SDK de Flutter (`Radio.groupValue`/`onChanged`, reemplazados por `RadioGroup` en Flutter 3.32+).

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Claude Opus 4.8, agente con acceso a terminal, en modo autónomo (continuación de la sesión de la Consulta #14, autorizada explícitamente por el equipo para operar sin supervisión).

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

Continuación de: "Ok, fusionemos las ramas [...] te voy a dejar en modo automático". Sin instrucción específica sobre el CI del PR — el agente detectó el fallo al verificar el estado del PR recién abierto y lo resolvió como parte de dejar la fusión realmente lista para revisión, no solo abierta.

**Resultado obtenido (fragmento de código, diseño, explicación).**

- 61 de los 65 issues eran mecánicos: imports sin usar o redundantes (7 archivos de `lib/` y `test/`), y documentación `///` faltante en miembros públicos (mayormente los 27 getters abstractos de `AppStrings` y varios campos/métodos de `AppContainer` en `main.dart`) — corregidos sin cambiar ningún comportamiento.
- Los 4 restantes eran una deprecación de la API de Flutter: `RadioListTile`/`Radio` con `groupValue`/`onChanged` propios está deprecado desde Flutter 3.32 a favor de envolver el grupo en un `RadioGroup<T>` ancestro. **Primer intento fallido**: se migró `settings_screen.dart` a `RadioGroup<T>` (firma verificada leyendo `radio_group.dart` del SDK instalado localmente, 3.35.6) y `flutter analyze` local quedó en "No issues found!" — pero al pushear, el CI real del proyecto **falló peor** (`undefined_method 'RadioGroup'`, `missing_required_argument`), porque el workflow de CI está fijado a **Flutter 3.24.5** (`subosito/flutter-action`), una versión anterior a que `RadioGroup` existiera. El SDK local recién instalado en esta sesión (3.35.6, ver Consulta #5) no coincide con la versión que el proyecto realmente fija en CI. **Corrección**: se revirtió a la API clásica (`groupValue`/`onChanged` en cada `RadioListTile`) con comentarios `// ignore: deprecated_member_use` puntuales, válida en ambas versiones — silencia el aviso en SDKs nuevos sin romper SDKs viejos.
- Verificación final: `flutter analyze` local (3.35.6) → "No issues found!", `flutter test` → 53/53 en verde, y — verificado explícitamente esta vez contra el runner real, no solo local — CI de GitHub Actions (Flutter 3.24.5) verde sobre el commit final del PR.

**Modificaciones realizadas por el equipo al resultado de la IA:**

- Ninguna intervención directa (sesión autónoma, equipo desconectado); el alcance se mantuvo deliberadamente acotado a limpieza mecánica de lint (imports/docs) y al fix de la API de `Radio`, sin tocar lógica de negocio.

**Lecciones aprendidas o limitaciones identificadas:**

- La deuda de lint que localmente parece "menor" (`flutter analyze` en verde antes de abrir el PR, en las Consultas #4/#5) puede acumularse silenciosamente entre archivos que distintos integrantes tocan en paralelo sin que nadie corra `flutter analyze` sobre el estado combinado hasta que un PR real lo expone.
- **Lección más importante de esta consulta**: "`flutter analyze` local en verde" no es suficiente cuando el SDK local no coincide con el que fija el CI real del proyecto — el mismo código puede ser "correcto" en una versión y "un error de compilación" en otra. Antes de dar por resuelto un fallo de CI, hay que confirmar contra el runner real (`gh run watch`), no solo replicar el comando localmente y confiar en el resultado.
- Antes de "adivinar" cómo migrar una API deprecada (el mensaje de `flutter analyze` sugiere la alternativa pero no siempre la firma exacta), leer el código fuente del SDK instalado localmente evita una migración plausible-pero-incorrecta.

---

## Consulta #16 — Caché local del catálogo de niveles para juego offline

**Tarea o problema abordado.**

El enunciado académico exige persistencia local del progreso del jugador, pero el equipo decidió ir más allá del mínimo: el catálogo de niveles debe descargarse del backend en cada inicio (`GET /levels`, ver Consulta #8) y quedar disponible localmente si el dispositivo pierde la red, en vez de depender de los 3 niveles estáticos empaquetados como assets (`JsonAssetLevelRepository` + `FallbackLevelRepository`, ver Consultas #7–#10). El diseño previsto: los 15 niveles viven exclusivamente en el backend (que ya valida su jugabilidad antes de persistirlos, `UpsertLevelUseCase` + `LevelSolvabilityValidator`); el cliente solo cachea localmente lo que ya descargó.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Claude Sonnet 5, agente con acceso a terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

El equipo planteó primero la pregunta de si convenía implementar persistencia offline del catálogo de niveles para acercarse más a la rúbrica del enunciado (revisada explícitamente citando la Sección 5.1 ítem 8 y la Sección 3.3 Capa 4). Tras acordar el diseño (un decorador `CachedLevelRepository` sustituyendo a `RemoteLevelRepository` + `FallbackLevelRepository` + `JsonAssetLevelRepository`), se pidió: "Sí, dale, empieza con la implementación".

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Repositorio con caché | `lib/infrastructure/level/cached_level_repository.dart` | `ILevelRepository`: intenta `GET /levels`, escribe write-through en `SharedPreferences` (JSON crudo, clave `cached_levels_json`); si la red falla, lee la última copia guardada; si no hay copia, relanza el error original |
| Wiring | `lib/main.dart` (`AppContainer._buildLevelRepository`) | Reemplaza la cadena `RemoteLevelRepository` → `FallbackLevelRepository` → `JsonAssetLevelRepository` por una sola instancia de `CachedLevelRepository`; se elimina el flag `ASSET_FALLBACK` |
| Tests | `test/infrastructure/level/cached_level_repository_test.dart` | 5 casos (`should_cache_levels_when_network_succeeds`, `should_return_cached_levels_when_network_fails_and_cache_exists`, `should_rethrow_when_network_fails_and_no_cache_exists`, `should_refresh_cache_when_network_recovers`, `findById`) con `MockHttpClient` y `SharedPreferences.setMockInitialValues` |
| Limpieza | — | Se eliminaron `json_asset_level_repository.dart`, `fallback_level_repository.dart`, sus tests, los 3 assets `assets/levels/level_0{1,2,3}.json` y su declaración en `pubspec.yaml` — ya no cumplían ningún rol una vez que existe caché real |

Diseño elegido: cachear el **JSON crudo** devuelto por `LevelApiClient.fetchAllLevels()` (antes de mapear a dominio), no el agregado `Level` — evita necesitar un serializador `Level → JSON` que no existía (`LevelDtoMapper` solo tenía `fromDto`/`fromJson`, nunca `toJson`).

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna corrección posterior; se verificó `flutter analyze` ("No issues found!") y la suite completa (`flutter test`, 52/52 en verde, incluyendo los 5 tests nuevos) antes de dar la tarea por terminada.

**Lecciones aprendidas o limitaciones identificadas.**

- El enunciado académico (Sección 5.1 ítem 8) solo exige explícitamente persistir *progreso y puntuaciones*, no el catálogo de niveles — cachear niveles es una decisión de arquitectura del equipo que excede el mínimo, no un requisito literal; se documenta aquí para que quede claro en la defensa por qué se hizo de todas formas (juego jugable offline, mejor uso del patrón Decorator ya existente).
- Quedó pendiente (fuera del alcance de esta consulta): el README todavía describe el catálogo de niveles y el estado de las capas con lenguaje de "Sprint 1/2" desactualizado respecto al código real — se decidió corregirlo en una pasada de documentación separada, no en cada commit individual.

---

## Consulta #17 — Bugs de refresco de progreso y avance offline tras probar la caché (Consulta #16 en vivo)

**Tarea o problema abordado.**

Al probar en vivo la caché de niveles de la Consulta #16 (backend y frontend corriendo de verdad, no solo tests), el equipo reportó dos comportamientos incorrectos: (1) tras ganar un nivel y volver a la lista con "Volver a niveles", el nivel recién completado no aparecía marcado hasta salir al home y reentrar; (2) con el backend apagado, ganar un nivel no mostraba el botón "Siguiente nivel" — el flujo de victoria se rompía sin red, contradiciendo el propósito mismo de la caché offline.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Claude Sonnet 5, agente con acceso a terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

"Ok, funciona pero hay un detalle, si logré superar 5 niveles por ejemplo, y decido volver a los niveles (presionando back to levels), esos 5 niveles no se muestran como superados hasta que salgo al home y vuelvo a entrar, y otra cosa, en teoria si apagas el back, yo deberia poder seguir jugando en el front no?"

**Resultado obtenido (fragmento de código, diseño, explicación).**

- **Causa raíz #1**: `VictoryScreen`/`DefeatScreen` usaban `Navigator.popUntil((route) => route.settings.name == '/levels')`, que reutiliza la instancia *ya existente* de `LevelSelectScreen` en el stack — su `LevelSelectController` había cargado el progreso una sola vez en `initState` y nunca se refrescaba al reaparecer. Corregido reemplazando por `pushNamedAndRemoveUntil('/levels', (route) => route.settings.name == '/home')`, que fuerza una ruta `/levels` nueva con un controlador recién creado (mismo patrón que ya usaba el logout).
- **Causa raíz #2**: `RecordVictoryUseCase.execute()` llamaba `await _progressApiClient.syncProgress(...)` **sin try/catch** después de guardar el progreso local y calcular el siguiente nivel — si esa llamada lanzaba (backend caído), la excepción abortaba el método completo *antes* del `return`, así que `RecordVictoryResult` (con el `nextLevel` ya calculado) nunca llegaba a la UI aunque el progreso ya estuviera guardado en disco. Corregido aislando solo la llamada de red en su propio try/catch interno; el resultado ahora siempre se devuelve con progreso + siguiente nivel, exponiendo el fallo de sync en un nuevo campo `RecordVictoryResult.syncError` en vez de propagar la excepción.
- Tests nuevos: `should_unlock_next_level_locally_when_progress_sync_fails` en `record_victory_use_case_test.dart`.
- Verificación en vivo repetida tras el fix: backend apagado, ganar nivel → aparece "Siguiente nivel" con mensaje de error de sync; "Volver a niveles" → progreso actualizado sin pasar por home.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna corrección adicional; verificado con `flutter analyze` limpio y suite completa en verde antes y después del fix.

**Lecciones aprendidas o limitaciones identificadas.**

- Un bug de este tipo (excepción de red abortando un método con trabajo local ya completado) es casi invisible en tests unitarios que mockean el HTTP client con éxito por defecto — solo se detectó al **probar la app corriendo de verdad** con el backend apagado, reforzando que la sección "Running the app locally" del README y la prueba manual con `--dart-define` siguen siendo necesarias más allá de la suite automatizada.
- `popUntil` vs. `pushNamedAndRemoveUntil` es una distinción sutil de Flutter con consecuencias reales en apps con controladores con estado cacheado en memoria (`ChangeNotifier` con `load()` en `initState`): reutilizar una ruta no reconstruye su widget ni vuelve a llamar `initState`.

---

## Consulta #18 — Cola de sincronización pendiente para progreso offline

**Tarea o problema abordado.**

Tras corregir los bugs de la Consulta #17, el equipo notó que `RecordVictoryUseCase` capturaba el error de `POST /progress/sync` pero **nunca reintentaba el envío** — si el jugador ganaba varios niveles sin red, esas victorias quedaban guardadas localmente para siempre pero nunca llegaban al backend, incumpliendo el espíritu del ítem 2 de la Sección 5.2 del enunciado ("sincronizar el progreso del jugador con el servidor"), que implica una sincronización eventual, no solo un intento único que se pierde si falla.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Claude Sonnet 5, agente con acceso a terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

"Ok, entonces ahora con el backend apagado, al encenderlo debería sincronizarse con el backend y enviar el progreso? [...] Sí, implementa la cola de sincronización pendiente."

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Modelo | `lib/application/models/pending_sync_entry.dart` | `PendingSyncEntry`: datos de una victoria no sincronizada (jugador, nivel, score, movimientos, tiempo), con `toJson`/`fromJson` |
| Puerto | `lib/application/ports/i_pending_sync_repository.dart` | `IPendingSyncRepository`: `add`/`loadAll`/`saveAll` |
| Infraestructura | `lib/infrastructure/progress/shared_preferences_pending_sync_repository.dart`, `.../in_memory_pending_sync_repository.dart` | Persistencia real (`SharedPreferences`, clave `pending_sync_queue`) y valor por defecto para tests/entornos sin `prefs` |
| Caso de uso | `lib/application/use_cases/sync_pending_progress_use_case.dart` | Reenvía las entradas pendientes del jugador de la sesión activa; deja intactas las de otros jugadores en el mismo dispositivo; las que sigan fallando quedan en la cola |
| Wiring | `RecordVictoryUseCase` ahora encola en `IPendingSyncRepository` cuando el sync falla; `LevelSelectController.load()` llama `SyncPendingProgressUseCase` como intento best-effort silencioso cada vez que se entra a la pantalla de niveles | — |
| Tests | `sync_pending_progress_use_case_test.dart` (3 casos), ampliación de `record_victory_use_case_test.dart` (verifica que la entrada quede encolada) | — |

Diseño: el disparo de reintento se ancla a `LevelSelectController.load()` (ya se ejecuta cada vez que se entra a esa pantalla) en vez de detectar conectividad explícitamente — simplemente se reintenta siempre y se descarta el resultado si vuelve a fallar; evita añadir un mecanismo de detección de red separado.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna corrección posterior; `flutter analyze` limpio y suite completa en verde (56/56) tras el cambio.

**Lecciones aprendidas o limitaciones identificadas.**

- La pregunta del equipo ("¿al encender el backend debería sincronizarse solo?") identificó correctamente una laguna real de arquitectura que ningún test unitario previo había cubierto, porque todos mockeaban el sync como exitoso o fallido una sola vez — ninguno probaba la secuencia "falla offline → vuelve la red → se reintenta".
- Quedó pendiente (fuera de esta consulta): la cola es best-effort y silenciosa; no hay UI que muestre "tienes N sincronizaciones pendientes", lo cual sería una mejora de transparencia pero no es requisito del enunciado.

---

## Consulta #19 — Sincronización bidireccional (pull+merge al login) y mensaje de modo sin conexión

**Tarea o problema abordado.**

Tras la Consulta #18 (cola de push), el equipo identificó que la sincronización seguía siendo unidireccional: el cliente **subía** progreso pero nunca lo **descargaba**. Consecuencia: entrar desde otro dispositivo o una ventana de incógnito con el mismo usuario mostraba el juego desde cero, porque el progreso vivía en el servidor pero nunca se traía de vuelta. Además, el error crudo de red (`ApiException(null): Network error calling ...`) se mostraba tal cual en pantalla, poco amigable. Este es el punto de fondo del ítem 5.2.2 del enunciado ("sincronizar el progreso del jugador con el servidor"): que el progreso sea del jugador (servidor), no del dispositivo.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Claude Sonnet 5 (backend + parte del frontend) y Claude Opus 4.8 (continuación frontend), agente con acceso a terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

"Sí, impleméntalo, endpoint GET y pull+merge al login, y también que en pantalla no se muestre el error de conexión, si no un mensaje de 'actualmente te encuentras jugando sin conexión, tu progreso se sincronizará con el servidor cuando tengas conexión o el servidor esté disponible' o algo así."

**Resultado obtenido (fragmento de código, diseño, explicación).**

Backend (repo `BackEnd-ArrowMaze`, documentado también en su propio `AI_USAGE.md`):
- Nuevo endpoint `GET /progress` (protegido por JWT) que devuelve todo el progreso del usuario autenticado; `userId` se toma del token, nunca del cliente.
- `IProgressRepository.findAllByUser`, `GetPlayerProgressUseCase`, wiring en el container, doc OpenAPI/Swagger, tests unitarios y de integración (401 sin JWT, devuelve lo sincronizado, vacío para usuario nuevo).

Frontend (este repo):

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Modelo | `lib/application/models/remote_level_progress.dart` | Espejo del DTO de `GET /progress` |
| Cliente HTTP | `ProgressApiClient.fetchProgress` | Descarga el progreso remoto |
| Merge de dominio | `PlayerProgress.mergeRemoteLevel` | Fusión best-of por nivel: el estado nunca retrocede, se toma el mínimo de movimientos/tiempo; como el servidor no persiste estrellas, usa `StarRating.one` de fallback al marcar completado y conserva las locales si eran mejores |
| Caso de uso | `lib/application/use_cases/pull_remote_progress_use_case.dart` | Descarga, fusiona nivel por nivel, y mantiene la cadena de progresión desbloqueando el sucesor de cada nivel completado |
| Wiring | `LevelSelectController.load()` → `_syncWithServer()` | Al entrar a niveles (primer paso tras login): pull+merge, luego push de pendientes; si algo falla marca `isOffline` sin romper el juego |
| Mensaje offline | `AppStrings.offlinePlayNotice` (ES/EN), banner en `LevelSelectScreen` y mensaje en `VictoryScreen` | Reemplaza el error técnico de red por el aviso amable pedido |
| Tests | `player_progress_merge_test.dart` (3), `pull_remote_progress_use_case_test.dart` (2), mock de `GET /progress` en el E2E factory | — |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna corrección posterior; `flutter analyze` limpio y suite completa en verde (61/61 frontend; backend 22 unitarios + integración) tras el cambio.

**Lecciones aprendidas o limitaciones identificadas.**

- **Limitación conocida**: el esquema de progreso del backend (`highScore/minMoves/minTimeInSeconds/isCompleted`) no persiste estrellas, así que las estrellas no sobreviven un viaje de ida y vuelta por el servidor — al descargar un nivel completado desde otro dispositivo se muestra con 1 estrella de fallback aunque en el dispositivo original tuviera 3. Se documenta como decisión consciente (no bloquea el progreso ni el desbloqueo, que es lo esencial del enunciado); ampliar el esquema del backend con `stars` sería la mejora natural.
- La sincronización quedó verdaderamente bidireccional: `POST` sube, `GET` baja, y `PlayerProgress.mergeRemoteLevel` (dominio) decide qué conservar — la regla "mejor de ambos" vive en la entidad, no en el caso de uso, consistente con cómo el backend ya lo hacía en `PlayerProgress.updateScore`.

---

## Consulta #20 — Mensajes de error amigables en login/registro

**Tarea o problema abordado.**

Al probar el registro/login con el mismo usuario desde otra sesión, el equipo notó que las pantallas de login y registro mostraban el `toString()` crudo de `ApiException` (p. ej. `ApiException(401): Invalid username or password`) en vez de un mensaje localizado y comprensible cuando la contraseña es incorrecta o el usuario ya existe.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Claude Sonnet 5, agente con acceso a terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

"[...] por cierto, se deben agregar notificaciones de error al momento de iniciar sesión de si la contraseña es incorrecta, de si el usuario ya existe y cosas por el estilo."

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Strings | `AppStrings.invalidCredentialsError`, `.usernameAlreadyExistsError`, `.authConnectionError` (ES/EN) | Mensajes localizados para 401, 409 y fallo de red |
| Helper | `lib/presentation/auth/auth_error_message.dart` (`authErrorMessage`) | Mapea `ApiException` por `statusCode` (401→credenciales inválidas, 409→usuario ya existe, `null`→error de conexión); cualquier otro código cae al mensaje crudo como fallback |
| Wiring | `login_screen.dart`, `register_screen.dart` | Reemplazan `widget.controller.error.toString()` por `authErrorMessage(AppStringsScope.of(context), widget.controller.error)` |
| Tests | `test/presentation/auth/auth_error_message_test.dart` (5 casos) | — |

El backend ya distinguía estos casos correctamente (`InvalidCredentialsError` 401, `UserAlreadyExistsError` 409, ver `AI_USAGE.md` del repo `BackEnd-ArrowMaze`); el gap estaba solo en cómo el cliente presentaba ese error, no en la lógica de negocio.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna corrección posterior; `flutter analyze` limpio y suite completa en verde (66/66) tras el cambio.

**Lecciones aprendidas o limitaciones identificadas.**

- El resto de las pantallas de auth (labels, validaciones de formulario) todavía usan texto en inglés embebido en vez de `AppStrings` — quedó fuera del alcance de esta consulta (se pidió específicamente sobre errores), pero es una inconsistencia de i18n a corregir en una pasada posterior.

---

## Consulta #21 — Bug real: los mensajes de error de auth nunca se mostraban (no era caché del navegador)

**Tarea o problema abordado.**

Tras la Consulta #20, el equipo probó con contraseña incorrecta y usuario repetido en una build nueva servida en un puerto distinto, con refresco duro del navegador — y el mensaje seguía sin aparecer. La primera hipótesis (mía) fue caché del service worker de Flutter Web; el equipo insistió en que probaba la URL y el puerto correctos. Verificar el log de compilación del proceso confirmó que la build sí era la nueva (sin errores, servida después de los cambios), lo que descartó la hipótesis de caché y obligó a revisar la lógica real.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Claude Sonnet 5, agente con acceso a terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

"Nada, estoy en la dirección correcta, hice refresco y no cambió nada, los mensajes no se muestran, enciende el servidor para ver si persiste el usuario con su progreso."

**Resultado obtenido (fragmento de código, diseño, explicación).**

Causa raíz encontrada en `LoginController` y `RegisterController` (`lib/presentation/auth/`): ambos `extends ChangeNotifier` pero **nunca llamaban a `notifyListeners()` ni se suscribían a los cambios de `AuthSessionController`** — el controlador que realmente muta `error`/`isLoading` tras un login/registro fallido. Las pantallas (`LoginScreen`, `RegisterScreen`) usan `ListenableBuilder(listenable: widget.controller, ...)`, escuchando al controlador de pantalla, no al `AuthSessionController` compartido. Resultado: el error quedaba correctamente calculado en memoria, pero la UI nunca se reconstruía para mostrarlo — un bug de wiring **preexistente**, no introducido por el mapeo de mensajes de la Consulta #20 (que en sí mismo era correcto, solo invisible).

Corrección: ambos controladores ahora se suscriben en el constructor (`_authSessionController.addListener(notifyListeners)`) y se desuscriben en `dispose()`.

| Componente | Ubicación | Cambio |
|------------|-----------|--------|
| `LoginController` | `lib/presentation/auth/login_controller.dart` | Reenvía notificaciones de `AuthSessionController` |
| `RegisterController` | `lib/presentation/auth/register_controller.dart` | Ídem |
| Tests de regresión | `test/presentation/auth/login_screen_test.dart`, `register_screen_test.dart` | Widget tests que simulan 401/409 vía `MockHttpClient` y verifican que el mensaje aparece **sin ninguna interacción adicional** tras el submit fallido — el escenario exacto que expuso el bug |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna corrección posterior; `flutter analyze` limpio y suite completa en verde (68/68, incluidos los 2 tests nuevos) tras el fix.

**Lecciones aprendidas o limitaciones identificadas.**

- **Caso de la IA equivocándose primero, documentado con honestidad**: mi primer diagnóstico (caché del service worker) era plausible pero incorrecto — Flutter Web en modo `debug` (`flutter run`, no `flutter build web`) no registra un service worker agresivo como en release, así que esa hipótesis nunca debió tener tanto peso. El equipo insistiendo en que probaba la instancia correcta, en vez de aceptar mi explicación, fue lo que forzó revisar el log de compilación y luego el código real — una lección de que "refresca el caché" es una respuesta cómoda que puede enmascarar un bug de wiring real si se acepta sin verificar.
- Patrón a vigilar en el resto del código: cualquier `ChangeNotifier` que envuelve a otro `ChangeNotifier` (como `LoginController`/`RegisterController` envolviendo `AuthSessionController`) debe reenviar explícitamente las notificaciones o la UI que escucha al envoltorio nunca se entera de cambios en el envuelto. Vale la pena auditar si existe el mismo patrón en otros controladores de pantalla que compongan sobre `AuthSessionController` u otros controladores compartidos.

---

## Consulta #22 — Aspecto AOP de logging/trazabilidad sobre `FireArrowUseCase`

**Tarea o problema abordado.**

El único aspecto transversal documentado en el cliente eran los domain events; faltaba algo más cercano al ejemplo literal del enunciado ("interceptar `MovePlayerUseCase.execute()` para registrar el estado del tablero antes y después del movimiento"). Se pidió agregar un aspecto de logging real, sin usar una librería de AOP.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Claude Sonnet 5, agente con acceso a terminal.

**Prompt o instrucción proporcionada.**

"Sí, dale con el aspecto AOP."

**Resultado obtenido.**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Puerto extraído | `IFireArrowUseCase` en `lib/application/use_cases/fire_arrow_use_case.dart` | Permite decorar el caso de uso sin que `GameController` dependa de la clase concreta |
| Puerto de logging | `lib/application/ports/i_use_case_logger.dart` (`IUseCaseLogger`) | Abstrae el mecanismo de logging (AOP: el caso de uso no lo conoce) |
| Decorador | `lib/application/use_cases/logging_fire_arrow_use_case_decorator.dart` | Registra estado del tablero (flechas restantes, movimientos, estado) antes/después de cada disparo, duración, y errores (relanzados, nunca silenciados) |
| Implementación | `lib/infrastructure/logging/console_use_case_logger.dart` | Logging real vía `dart:developer` |
| Wiring | `AppContainer.buildGameController()` en `lib/main.dart` | Envuelve `FireArrowUseCase` con el decorador; `FireArrowUseCase` sigue sin ninguna línea de logging |
| Tests | `test/application/use_cases/logging_fire_arrow_use_case_decorator_test.dart` (3 casos) | Transparencia del resultado, mensajes antes/después, relanzamiento de errores |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna corrección posterior; `flutter analyze` limpio y suite completa en verde (82/82) tras el cambio.

**Lecciones aprendidas o limitaciones identificadas.**

- Extraer una interfaz de un caso de uso ya en uso (`FireArrowUseCase` → `IFireArrowUseCase`) fue un cambio de bajo riesgo porque `GameController` ya lo recibía por constructor (inyección de dependencias existente) — solo cambió el tipo del parámetro, cero cambios de lógica en `GameController` ni en las pantallas.
- Reutilizar el patrón Decorator (ya usado en `CachedLevelRepository`) para el aspecto AOP, en vez de introducir un mecanismo distinto, mantiene la arquitectura consistente y es más fácil de defender en la sustentación: "usamos el mismo patrón para dos problemas distintos —caché e instrumentación— porque ambos son, estructuralmente, 'añadir comportamiento a una implementación existente sin modificarla'".

---

## Consulta #23 — Hot-reload del catálogo: botón de actualización y notificación en selección de niveles

**Tarea o problema abordado.**

El backend ya podía sembrar niveles desde `levels/*.json` y sincronizarlos en caliente (Observer en el repo `BackEnd-ArrowMaze`, Consulta #16), pero el cliente seguía mostrando el catálogo cacheado en memoria hasta reiniciar la app. Se solicitó un botón simple en la pantalla de niveles que fuerce `GET /levels`, actualice la lista y notifique al usuario si hubo niveles nuevos.

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura del repositorio y ejecución de tests.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Complementar el cliente Flutter con un botón de actualización del catálogo en la pantalla de selección de niveles: invalidar la caché del repositorio, volver a descargar `GET /levels`, refrescar la UI y mostrar una notificación (SnackBar) con el resultado; añadir i18n, tests y documentación en `AI_USAGE.md` con redacción técnica profesional, alineado con el hot-reload del backend vía patrón Observer.

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Puerto | `ILevelRepository.invalidateCache()` | Contrato para descartar caché en memoria |
| Infra | `CachedLevelRepository`, `RemoteLevelRepository` | Implementación de invalidación |
| Caso de uso | `RefreshLevelsUseCase` + `LevelCatalogRefreshResult` | Compara ids antes/después del refresh |
| Controlador | `LevelSelectController.refreshCatalog()` | Orquesta refresh y reordena niveles |
| UI | `level_select_screen.dart` | `IconButton(Icons.refresh)` + `SnackBar` |
| i18n | `app_strings.dart` | `refreshLevelsTooltip`, `levelsCatalogUpdated`, etc. |
| Wiring | `main.dart` | Inyecta `RefreshLevelsUseCase` en el controlador |
| Tests | `refresh_levels_use_case_test.dart`, `cached_level_repository_test.dart`, `level_select_screen_test.dart` | Conteos, invalidación HTTP y notificación visible |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión del equipo tras merge.

**Lecciones aprendidas o limitaciones identificadas.**

- `RefreshLevelsUseCase` depende de que la segunda llamada a `findAll()` vea datos distintos; en producción eso ocurre cuando el backend ya upserteó el JSON nuevo (watcher) y la app invalida caché antes de `GET /levels`.
- Los niveles nuevos aparecen bloqueados hasta completar el anterior: `EnsureInitialProgressUseCase` no se re-ejecuta en el refresh (comportamiento deseado para no resetear progreso).

---

## Consulta #24 — Diseño visual minimalista: paleta Tollens, flechas multi-celda y tablero

**Tarea o problema abordado.**

Alinear la interfaz del cliente con la identidad visual acordada por el equipo (paleta Tollens minimalista + logo del laberinto): flechas dibujadas como trazos continuos de hasta **3 celdas** (cabeza + 2 segmentos de cuerpo), tablero con bordes redondeados y rejilla suave, y tema global coherente en lugar del `deepPurple` genérico de Material.

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura del repositorio y ejecución de tests.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Implementar el rediseño visual del cliente Flutter según la paleta Tollens y el logo del laberinto: flechas con trazo continuo que abarquen hasta tres celdas del tablero, tablero minimalista con esquinas redondeadas, tema global coherente, validación del límite de segmentos en el contrato compartido, documentación dartdoc en español en cada función nueva, y registro en `AI_USAGE.md` con redacción técnica profesional.

**Resultado obtenido.**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Paleta | `lib/presentation/theme/app_colors.dart` | Colores Tollens + acentos del logo (slate, rosa bloqueo, azul activo, verde éxito) |
| Tema | `lib/presentation/theme/app_theme.dart` | `ThemeData` Material 3; wiring en `main.dart` |
| Geometría | `lib/presentation/game/widgets/arrow_path_geometry.dart` | Ordena cola→cabeza; valida `body.length ≤ 2` |
| Pintor | `lib/presentation/game/widgets/arrow_board_painter.dart` | `CustomPainter`: rejilla, muros, trazos gruesos y punta triangular |
| Tablero | `lib/presentation/game/widgets/board_view.dart` | `Stack`: pintor + capa de toques transparente |
| Contrato | `lib/contract/level_contract.dart` | `kMaxArrowBodySegments = 2`; rechaza JSON inválido en `fromJson` |
| UI | `home_screen.dart`, `level_select_screen.dart` | Iconos y estados con `AppColors` |
| Tests | `test/presentation/game/arrow_path_geometry_test.dart` | Orden L-shaped, línea recta, validación de límite |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión del equipo tras merge.

**Lecciones aprendidas o limitaciones identificadas.**

- Separar **capa visual** (`CustomPaint`) de **capa de toques** (`GestureDetector` por celda) permite flechas multi-celda sin perder las `ValueKey` que usan los widget tests existentes.
- El límite de 3 celdas debe validarse en el contrato wire y en el backend para que el pintor nunca reciba geometrías inesperadas.
- Flechas en forma de L requieren encadenar segmentos por adyacencia, no solo ordenar por fila/columna.

---

## Consulta #25 — Flechas de longitud arbitraria, `optimalMoves` desde el backend y fix de navegación en Retry

**Tarea o problema abordado.**

Tres problemas encontrados al probar la app con niveles reales de mayor tamaño y variedad: (1) el límite de 3 celdas por flecha (Consulta #24) era una limitación visual mal convertida en regla de negocio — la regla real es "mínimo 1 celda de cuerpo, sin máximo"; (2) `LevelDtoMapper.fromDto` recalculaba la ruta óptima con un BFS exhaustivo sobre el espacio de estados al cargar cada nivel, lo que congelaba la pestaña completa con niveles de muchas flechas (48 en un caso real); (3) el botón "Reintentar" de la pantalla de derrota hacía `Navigator.pop()`, lo que revelaba la instancia original (y desactualizada) de `LevelSelectScreen` en vez de reabrir el nivel — causando que niveles ya superados aparecieran como no completados.

**Herramienta de IA utilizada.**

- Claude Code (Claude Sonnet 5), sesión interactiva de terminal con acceso de lectura/escritura al repositorio, ejecución de `flutter test` y control de versiones.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Solucionar que las flechas tengan cualquier longitud (no solo 5); deben tener al menos una cabeza y una celda de cuerpo. El cliente se congela al cargar niveles grandes — mover el cálculo de la ruta óptima al backend. Si estoy jugando el nivel 19 y lo superó, juego el 20 y lo superó, pero pierdo en el 21 y le doy retry, no reabre el nivel 21 sino que sale a la pantalla de niveles y el 19/20 aparecen como no superados.

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Contrato | `lib/contract/level_contract.dart` | `kMinArrowBodySegments = 1`; `optimalMoves` opcional, leído del servidor |
| Mapper | `lib/interface_adapters/level_dto_mapper.dart` | Ya no ejecuta `ShortestPathCalculator`; usa `dto.optimalMoves ?? arrows.length` |
| Navegación | `lib/presentation/result/defeat_screen.dart` | El botón Retry ahora hace `pushReplacementNamed('/game', arguments: level)` en vez de `pop()` |
| Tests | `level_dto_mapper_test.dart`, `defeat_screen_test.dart` | Cobertura del respaldo `arrows.length`, del valor del servidor, y de la navegación de Retry |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- El equipo decidió explícitamente no mantener una verificación de solvabilidad redundante en el cliente tras mover `optimalMoves` al backend, confiando en que el backend ya valida cada nivel antes de aceptarlo (single source of truth).
- Se identificó que `ShortestPathCalculator` sigue siendo necesario para `LevelFactory` (generación procedural de niveles, camino distinto al de carga desde el backend) y se dejó sin tocar.

**Lecciones aprendidas o limitaciones identificadas.**

- Un límite de validación "copiado" de una limitación visual en lugar de derivado de la regla de negocio real (cada disparo retira exactamente una flecha, así que el óptimo siempre es `arrows.length`) es fácil de introducir sin darse cuenta, y solo se detectó al medir con datos reales.
- Todo el flujo Game→Victory→Game→…→Defeat usa `pushReplacementNamed`, así que cualquier pantalla que necesite "volver" debe forzar una ruta nueva en vez de `pop()`, o revelará una instancia congelada de la pantalla anterior — el equipo ya había resuelto esto para los botones "volver a niveles", pero se pasó por alto en "Retry".
- Medir antes de optimizar: se verificó con un script aislado que la validación de solubilidad del backend tarda milisegundos incluso con 48 flechas, evitando construir una optimización (caché por hash de contenido) que no hacía falta todavía.

---

## Consulta #26 — Refinamiento del tablero: trazo fino, cabeza al borde y fondo sin rejilla

**Tarea o problema abordado.**

Tras el rediseño visual (Consulta #24), al probar niveles con flechas verticales largas (p. ej. espiral con cabeza apuntando hacia arriba en el borde del tablero) se observaron tres problemas de legibilidad: (1) la punta triangular se dibujaba centrada en la celda de la cabeza y el trazo del cuerpo llegaba hasta el mismo centro, generando solapamiento en la unión; (2) el grosor del trazo (18 % del tamaño de celda) ocultaba demasiado los cruces entre flechas; (3) la rejilla de fondo competía visualmente con el estilo minimalista acordado — se pidió dejar solo muros y fondo liso.

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura del repositorio.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Refinar el renderizado del tablero en `ArrowBoardPainter` para mejorar la legibilidad de flechas largas con cabeza orientada hacia arriba: corregir la posición de la punta triangular (evitar solapamiento con el trazo del cuerpo), reducir el grosor del trazo para que los cruces entre flechas se distingan con claridad, y eliminar la cuadrícula de fondo dejando únicamente los muros y el fondo liso del tablero.
>
> Implementar las mejoras propuestas en el código, añadir tests unitarios de la geometría de cabeza cuando aplique, registrar la consulta en `AI_USAGE.md` conforme a las normas del proyecto (Consulta #7), y proponer un mensaje de commit en Conventional Commits.

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Geometría de cabeza | `lib/presentation/game/widgets/arrow_path_geometry.dart` | `headTip()` ancla la punta al borde de la celda según `Direction`; `headBase()` calcula dónde debe terminar el trazo del cuerpo |
| Pintor | `lib/presentation/game/widgets/arrow_board_painter.dart` | Elimina `_paintGrid()`; grosor `0.12×` celda; cuerpo termina en `headBase`, no en el centro; punta más estrecha (`headLength × 1.8`, `headWidth × 1.2`) |
| Contenedor | `lib/presentation/game/widgets/board_view.dart` | Borde del tablero suavizado (`AppColors.sand`) sin líneas de rejilla |
| Tests | `test/presentation/game/arrow_path_geometry_test.dart` | Casos para `headTip` (flecha `UP` en fila 0) y `headBase` |

**Constantes de renderizado aplicadas:**

```dart
static const _strokeFactor = 0.12;      // antes 0.18
static const _headLengthFactor = 1.8;     // antes 2.2
static const _headWidthFactor = 1.2;      // antes 1.6
static const _headMarginFactor = 0.5;     // inset desde el borde de celda
```

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión del equipo tras merge.

**Lecciones aprendidas o limitaciones identificadas.**

- Separar **geometría** (`headTip` / `headBase`) del **pintado** facilita probar posicionamiento sin widget tests de `CustomPainter`.
- Acortar el trazo antes de la cabeza evita el efecto “doble grosor” más que agrandar la punta.
- Quitar la rejilla no afecta la capa de toques (`_BoardTouchGrid`): la detección por celda sigue intacta.
- En niveles muy densos, un grosor menor puede reducir el área táctil visual; si hiciera falta, el ajuste fino sería subir `_strokeFactor` a `0.13` sin reintroducir la rejilla.

---

## Consulta #27 — Flechas con esquinas limpias, navegación global y marco móvil en web

**Tarea o problema abordado.**

Tres mejoras de producto detectadas al probar niveles espirales (p. ej. `level-17`): (1) renderizado de flechas con codos, cabezas desalineadas y cruces irregulares frente a la referencia visual del equipo; (2) acceso inconsistente a **Ajustes** y **Clasificación** (solo en algunas pantallas); (3) en Flutter Web la app ocupaba todo el viewport del navegador en lugar de simular un dispositivo móvil.

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura del repositorio.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Corregir el renderizado de flechas para que los cruces y la unión cabeza–cuerpo coincidan con la referencia visual (trazo continuo, esquinas redondeadas, punta integrada). Añadir botones de Ajustes y Clasificación en todas las pantallas; en web, mostrar la aplicación dentro de un marco con proporciones de teléfono móvil; habilitar acceso al leaderboard global desde cualquier vista. Registrar la consulta en `AI_USAGE.md` con redacción técnica profesional.

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Geometría | `arrow_path_geometry.dart` | `simplifyCollinear()`, `buildBodyPath()` con esquinas `quadraticBezierTo` y tramos axis-aligned hacia cabeza |
| Pintor | `arrow_board_painter.dart` | `StrokeCap.butt`, base del triángulo = `strokeWidth/2`, cuerpo vía `buildBodyPath` |
| Nav global | `app_nav_actions.dart` | Iconos leaderboard + settings reutilizables; `leaderboardLevelId` opcional |
| Hub ranking | `leaderboard_hub_screen.dart` | Lista niveles → ranking por `levelId` cuando no hay contexto de partida |
| Marco web | `phone_frame.dart` | En `kIsWeb`, escala 390×844 con bezel y sombra |
| Pantallas | home, login, register, levels, game, victory, defeat, settings, leaderboard | `AppBar.actions` con `AppNavActions` |
| Rutas | `main.dart` | `/leaderboard` sin args → hub; con `String` → detalle; `PhoneFrame` envuelve `MaterialApp` |
| Tests | `arrow_path_geometry_test.dart`, `home_screen_test.dart` | Colinealidad, esquina L, navegación a settings vía `app-nav-settings` |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión del equipo tras merge.

**Lecciones aprendidas o limitaciones identificadas.**

- Los vértices por celda en polilíneas largas generan artefactos de unión aunque la línea sea recta; simplificar colineales antes de pintar es obligatorio en grids densos.
- `StrokeCap.round` + triángulo separado siempre deja costura visible; `butt` + ancho de base igual al trazo integra mejor la cabeza.
- El leaderboard del backend es **por nivel** (`GET /leaderboard/:levelId`); el hub centraliza el acceso global sin cambiar el contrato API.
- `PhoneFrame` solo afecta web; builds nativos mantienen pantalla completa del dispositivo.

---

## Consulta #28 — Correcciones UX: leaderboard, navegación contextual, progreso y cabeza de flecha

**Tarea o problema abordado.**

Seis incidencias detectadas en pruebas manuales tras la Consulta #27: (1) crash en el hub de clasificación al ordenar una lista inmutable del repositorio; (2) icono de leaderboard redundante en pantallas de clasificación; (3) icono de ajustes redundante en la pantalla de settings; (4) flecha “atrás” visible en Home tras refrescar el navegador; (5) niveles completados no reflejados al volver del juego sin recrear la ruta de niveles; (6) cabeza de flecha demasiado pequeña para leer la dirección de disparo.

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura del repositorio.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Corregir seis detalles de UX detectados en pruebas: manejo amigable del leaderboard vacío (evitar errores técnicos), ocultar iconos de navegación redundantes en clasificación y ajustes, eliminar la flecha atrás en la pantalla principal, refrescar el progreso de niveles completados al regresar del juego, y ampliar la cabeza de las flechas para que la dirección sea legible. Registrar la consulta en `AI_USAGE.md` con redacción técnica profesional.

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Hub ranking | `leaderboard_hub_screen.dart` | `List<Level>.from(...)` antes de `sort`; mensajes i18n en vacío/error |
| Detalle ranking | `leaderboard_screen.dart` | `leaderboardNoScores` / `leaderboardLoadFailed`; oculta icono leaderboard |
| Nav contextual | `app_nav_actions.dart` | Flags `showLeaderboard` / `showSettings` |
| Home raíz | `home_screen.dart` | `PopScope(canPop: false)` + `automaticallyImplyLeading: false` |
| Progreso | `level_select_screen.dart` + `app_route_observer.dart` | `RouteAware.didPopNext` → `refreshProgress()` |
| Flechas | `arrow_board_painter.dart` | `headLengthFactor 2.8`, `headWidthFactor 1.0` |
| i18n | `app_strings.dart` | Cadenas EN/ES para estados vacío/error del leaderboard |
| Tests | `leaderboard_screen_test.dart` | Mensajes i18n y ausencia del icono leaderboard en detalle |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión del equipo tras merge.

**Lecciones aprendidas o limitaciones identificadas.**

- Repositorios que devuelven `List.unmodifiable` exigen copia defensiva antes de cualquier mutación in-place (`sort`, `add`, etc.).
- Acciones globales de AppBar deben ser contextuales; un icono que navega a la pantalla actual confunde al usuario.
- `LevelSelectController.load()` en `initState` no basta si la pantalla permanece en el stack: hace falta `RouteAware` o recrear la ruta al volver del juego.
- Ampliar solo la longitud de la punta sin el ancho deja flechas “agujas”; conviene escalar ambos factores proporcionalmente al grosor del trazo.

---

## Consulta #29 — Nombres visibles de niveles y navegación en Ajustes

**Tarea o problema abordado.**

Dos mejoras de producto detectadas en pruebas: (1) en la pantalla de **Ajustes** seguía visible el icono de clasificación, redundante con el acceso global desde otras vistas; (2) la UI mostraba el identificador técnico del nivel (`level-01`, `simple-1`) en lugar del campo **`name`** definido en los JSON del catálogo (p. ej. “Primer Contacto”), porque el contrato compartido backend–frontend no transportaba ese campo hasta el dominio Flutter.

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura de los repositorios frontend y backend.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Implementar los ajustes pendientes de la revisión UX: ocultar el botón de clasificación en la pantalla de Ajustes; extender el contrato compartido de niveles con el campo `name` y mostrar ese nombre legible en la UI (selector de niveles, partida, hub y detalle de ranking) en lugar del identificador interno. Actualizar mappers, entidades y pruebas en backend y frontend. Registrar la consulta en `AI_USAGE.md` con redacción técnica profesional.

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Contrato wire | `docs/contract/level.contract.ts` + `lib/contract/level_contract.dart` | Campo opcional `name` en `StructuredLevelJsonDto` |
| Dominio BE | `LevelDefinition`, `LevelBuilder`, `LevelJsonMapper` | Propiedad `name`; fallback `name ?? id` al mapear |
| Dominio FE | `level.dart` | `displayName` + getter `displayLabel` (fallback a `id`) |
| Mapper FE | `level_dto_mapper.dart` | `displayName: dto.name?.trim() ?? ''` |
| UI | `level_select_screen`, `game_screen`, `leaderboard_hub_screen`, `leaderboard_screen` | Títulos con `displayLabel` / `levelTitle` |
| Nav | `settings_screen.dart` | `AppNavActions(showSettings: false, showLeaderboard: false)` |
| Rutas | `leaderboard_route_args.dart`, `main.dart`, `app_nav_actions.dart` | Pasar `levelId` + título visible al abrir ranking |
| Tests | `level_dto_mapper_test.dart`, `LevelJsonMapper.spec.ts`, `LevelDefinition.test.ts` | Round-trip de `name` y etiqueta visible |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión del equipo tras merge.

**Lecciones aprendidas o limitaciones identificadas.**

- Los JSON de catálogo pueden incluir metadatos de presentación (`name`) que no llegan a la UI si el contrato wire no los expone; conviene mantener paridad estricta entre `docs/contract/` y `lib/contract/`.
- El API de leaderboard sigue keyed por `levelId`; el nombre es solo capa de presentación y debe propagarse por argumentos de navegación cuando la pantalla no tiene el objeto `Level` cargado.
- Ocultar iconos de navegación global debe aplicarse de forma simétrica (leaderboard en settings, settings en settings, leaderboard en leaderboard) para evitar acciones que no cambian de contexto.

---

## Consulta #30 — Sistema de efectos de sonido por contexto de juego y temporizador por nivel

**Tarea o problema abordado.**

Integrar los assets de audio aportados por el equipo en una experiencia sonora coherente con las reglas del juego, y completar la presión temporal de partida con cuenta regresiva visible. Se requería: (1) diagnosticar por qué `background.mp3` no reproducía música de fondo en la interfaz; (2) asignar cada carpeta de sonidos a un único contexto de uso — sin mezclar efectos entre tablero, botones de navegación y resultados de partida; (3) reproducir sonidos de extracción de flecha de forma aleatoria; (4) distinguir colisión flecha–flecha de bloqueo por muro; (5) calcular por nivel el tiempo disponible para completarlo (`maxTimeInSeconds` del wire format o estimación desde `optimalMoves`); (6) mostrar el temporizador en vivo durante la partida y reproducir `times_up.mp3` exclusivamente al agotarse el tiempo.

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura del repositorio, terminal y exploración del árbol de assets.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Integrar el sistema de audio del juego con los assets en `assets/audio/`, respetando el contexto de cada carpeta:
>
> - **`background.mp3`**: música de fondo en bucle para toda la interfaz; diagnosticar por qué no suena al arrancar (especialmente en Flutter Web).
> - **`Tap_sound/`** (5 variantes): reproducir **un sonido aleatorio** cada vez que una flecha **sale exitosamente** del tablero; no usar estos archivos en botones ni en otros eventos.
> - **`General_Tap/`**: clic de **botones generales** de la UI (navegación, formularios, selección de nivel); no debe sonar al tocar celdas del tablero ni al ganar, perder o mover flechas.
> - **`Level_Cleared/`**: sonido **exclusivo** al completar un nivel (victoria); no superponerlo con el tap de la última flecha extraída.
> - **`Movement_Not_Allowe/`**: sonido **exclusivo** cuando una flecha **choca con otra flecha**; no debe sonar en bloqueos por muro ni en derrota por agotar movimientos.
> - **`times_up.mp3`**: sonido **exclusivo** al agotar el tiempo del nivel; implementar temporizador en vivo calculado por nivel y mostrarlo en la pantalla de juego.
>
> Mantener la arquitectura existente (`IAudioService`, mute global, `NoOpAudioService` para tests) y documentar la consulta en `AI_USAGE.md`.

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Asset / carpeta | Método en `IAudioService` | Cuándo suena |
|-----------------|---------------------------|--------------|
| `background.mp3` | `startBackgroundMusic()` / `stopBackgroundMusic()` | Bucle al iniciar la app (respeta mute); se detiene al silenciar |
| `Tap_sound/tap_sound_1…5.mp3` | `playArrowExtracted()` | Tras `MoveResultType.extracted`, si la partida **no** terminó en victoria |
| `General_Tap/general_click_sound.mp3` | `playButtonClick()` | Botones e ítems de navegación vía `withButtonClick` |
| `Level_Cleared/level_cleared.mp3` | `playLevelCleared()` | Solo cuando `game.isWon` (nivel superado) |
| `Movement_Not_Allowe/not_allowed_movement.mp3` | `playMovementNotAllowed()` | Solo si `MoveResult.isBlocked` **y** otra flecha ocupa la celda de bloqueo (no muro) |
| `times_up.mp3` | `playTimeUp()` | Solo cuando `GameLossMessage.timeExceeded` (tiempo agotado) |
| *(sin asset)* | `playDefeat()` | Solo derrota por movimientos agotados (`SystemSound`) |

**Temporizador por nivel:**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Calculador | `level_time_limit_calculator.dart` | Usa `timeLimit` del wire format; si falta, estima `optimalMoves × seg/dificultad + margen` |
| Dominio | `level.dart`, `game.dart` | `playableTimeLimitSeconds`, `remainingSeconds`, `isTimeRunningLow`; derrota cuando `elapsed >= limit` |
| Controlador | `game_controller.dart` | `Timer.periodic` cada 1 s; `_playLossAudio` distingue tiempo vs. movimientos |
| UI | `game_screen.dart`, `game_time_formatter.dart` | Muestra `Tiempo: mm:ss / mm:ss`; rojo en los últimos 10 s |
| i18n | `app_strings.dart` | `timeRemainingLabel(remaining, total)` en es/en |

**Componentes de audio implementados o modificados:**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Puerto de audio | `lib/application/ports/i_audio_service.dart` | API explícita por contexto de UX |
| Implementación | `lib/infrastructure/audio/app_audio_service.dart` | Reproducción con `audioplayers`; selección aleatoria; verificación previa con `rootBundle.load` |
| Scope + helpers UI | `audio_scope.dart`, `button_click.dart` | `AudioScope` envuelve `MaterialApp`; clic en botones generales |
| Tests | `level_time_limit_calculator_test.dart`, `no_op_audio_service.dart` | Cobertura del cálculo de tiempo y dobles de audio |

**Fragmento representativo del enrutamiento de audio en partida:**

```dart
if (outcome.game.isWon) {
  await _audioService.playLevelCleared();
} else if (outcome.game.isLost) {
  await _playLossAudio(outcome.game); // playTimeUp o playDefeat
} else if (outcome.result.isExtracted) {
  await _audioService.playArrowExtracted();
} else if (_isBlockedByAnotherArrow(outcome.game, outcome.result)) {
  await _audioService.playMovementNotAllowed();
}
```

**Diagnóstico de `background.mp3`:**

- El asset y la ruta en `pubspec.yaml` (`assets/audio/`) estaban correctos.
- En **Flutter Web**, la política de **autoplay** impide iniciar audio sin gesto del usuario; `startBackgroundMusic()` se invoca con `unawaited()` en `initialize()` para no bloquear `runApp()`.
- Tras añadir o renombrar MP3 hace falta **restart completo** de la app, no hot reload.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- El equipo aportó los archivos MP3 reales (`background.mp3`, variantes en `Tap_sound/`, `times_up.mp3`, etc.) y validó la asignación por carpeta en pruebas manuales.
- `playDefeat()` sigue usando `SystemSound` del sistema: no hay asset dedicado de derrota por movimientos.

**Lecciones aprendidas o limitaciones identificadas.**

- Un mismo `MoveResultType.blocked` en dominio puede representar causas distintas (muro vs. flecha); la capa de presentación debe filtrar antes de elegir el efecto sonoro.
- Separar métodos en `IAudioService` por **intención de UX** evita acoplar sonidos genéricos al tablero.
- Los nombres de archivo con espacios o apóstrofes (`Time's_Up.mp3`) son frágiles en bundles Web; se normalizó a `times_up.mp3`.
- El temporizador en UI requiere `Timer.periodic` en el controlador además de la comprobación en dominio al mover, para derrotar al jugador aunque no toque el tablero.
- En Web, cualquier efecto que dependa de `AudioContext` debe asumirse bloqueado hasta el primer gesto del usuario.
