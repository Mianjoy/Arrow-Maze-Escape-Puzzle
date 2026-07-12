# Registro de Uso de Inteligencia Artificial

Este documento registra cada consulta realizada a herramientas de IA durante el desarrollo del proyecto **Arrow Maze Escape Puzzle**.

## Herramientas utilizadas

| Herramienta | Versión / modelo | Rol en el flujo de trabajo |
|---|---|---|
| Cursor AI / Cursor Agent (Composer) | Integrado en el IDE (modelo Claude) | Implementación asistida en las primeras consultas del proyecto, con acceso de lectura/escritura al repositorio y, en varias sesiones, también al repositorio backend en paralelo. |
| Claude Code | Claude Sonnet 5 (mayoría de sesiones); Claude Opus 4.8 en tramos específicos de sesiones largas | Agente principal desde media sesión en adelante: sesiones interactivas de terminal con acceso de lectura/escritura al repositorio (y frecuentemente también al repositorio backend), ejecución real de `flutter analyze`/`flutter test`, inspección de artefactos generados (APK, almacenamiento local del simulador), y modo de planificación explícita con aprobación previa para cambios de mayor alcance. |

## Registro de uso por tarea

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

Integrar los assets de audio aportados por el equipo en una experiencia sonora coherente con las reglas del juego, completar la presión temporal de partida con cuenta regresiva visible, y corregir tres problemas detectados en pruebas manuales: (1) diagnóstico de `background.mp3`; (2) asignación de cada carpeta de sonidos a un único contexto de UX; (3) sonido dedicado al agotar movimientos; (4) pausa del temporizador al navegar a Leaderboard/Ajustes desde la partida; (5) desbloqueo de audio en Web tras el primer gesto del usuario (síntoma: parecía todo muteado hasta togglear silencio).

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
> - **`no_movements_left.mp3`** (orig. `0_movements.mp3`): sonido **exclusivo** al agotar los movimientos permitidos; no usarlo en derrota por tiempo ni en otros eventos.
> - **Temporizador en pausa**: al salir de la partida hacia **Leaderboard** o **Ajustes**, detener la cuenta regresiva y reanudarla al volver, sin consumir tiempo mientras la pantalla de juego no está visible.
> - **Desbloqueo de audio en Web**: corregir el comportamiento en el que la app parece silenciada al iniciar hasta togglear mute; el audio debe activarse tras el primer gesto real del usuario.
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
| `no_movements_left.mp3` | `playNoMovementsLeft()` | Solo cuando `GameLossMessage.movesExceeded` (movimientos agotados) |

**Temporizador por nivel:**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Calculador | `level_time_limit_calculator.dart` | Usa `timeLimit` del wire format; si falta, estima `optimalMoves × seg/dificultad + margen` |
| Dominio | `level.dart`, `game.dart` | `playableTimeLimitSeconds`, `remainingSeconds`, `isTimeRunningLow`; derrota cuando `elapsed >= limit` |
| Controlador | `game_controller.dart` | `Timer.periodic` cada 1 s; `pauseGame`/`resumeGame`; `_playLossAudio` distingue tiempo vs. movimientos; `ensureAudioUnlocked` en cada toque |
| UI | `game_screen.dart`, `game_time_formatter.dart` | Muestra `Tiempo: mm:ss / mm:ss`; `RouteAware` pausa al abrir Leaderboard/Ajustes |
| Dominio (pausa) | `game.dart` | `totalPausedDuration` + `pausedAt`; `elapsedSeconds` excluye tiempo en pausa |
| Audio Web | `ensureAudioUnlocked()` | Reintenta `startBackgroundMusic` tras gesto; invocado desde `withButtonClick` y `onCellTapped` |
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
  await _playLossAudio(outcome.game); // playTimeUp o playNoMovementsLeft
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

- El equipo aportó los archivos MP3 reales (`background.mp3`, variantes en `Tap_sound/`, `times_up.mp3`, `no_movements_left.mp3`, etc.) y validó la asignación por carpeta en pruebas manuales.

**Lecciones aprendidas o limitaciones identificadas.**

- Un mismo `MoveResultType.blocked` en dominio puede representar causas distintas (muro vs. flecha); la capa de presentación debe filtrar antes de elegir el efecto sonoro.
- Separar métodos en `IAudioService` por **intención de UX** evita acoplar sonidos genéricos al tablero.
- Los nombres de archivo con espacios, apóstrofes o prefijos numéricos (`Time's_Up.mp3`, `0_movements.mp3`) son frágiles en bundles Web; conviene normalizarlos (`times_up.mp3`, `no_movements_left.mp3`).
- El temporizador en UI requiere `Timer.periodic` en el controlador además de la comprobación en dominio al mover, para derrotar al jugador aunque no toque el tablero.
- Pausar solo el `Timer` no basta: `elapsedSeconds` debe descontar `totalPausedDuration` en dominio, o el tiempo seguiría corriendo al volver de Leaderboard/Ajustes.
- En Web, `ensureAudioUnlocked()` tras el primer clic desbloquea el `AudioContext` sin obligar al usuario a togglear mute; el flag `isMuted` por defecto es `false`, el síntoma era autoplay bloqueado, no mute persistente.

---

## Consulta #31 — Migración de assets de audio de MP3 a WAV

**Tarea o problema abordado.**

El equipo decidió convertir la biblioteca completa de sonidos del juego de **MP3** (comprimido con pérdida) a **WAV** (PCM sin compresión), con el objetivo de mejorar la calidad percibida y unificar el códec de los assets. Se requería alinear el código Flutter, la documentación de `assets/audio/` y el registro de IA con el nuevo formato, **sin alterar** la asignación contextual de cada sonido definida en la Consulta #30 (misma carpeta → mismo evento de UX; solo cambian extensión y códec del archivo).

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura del repositorio y exploración del árbol `assets/audio/`.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> El equipo ha reemplazado todos los assets de audio del proyecto de **MP3** a **WAV**. Actualizar el sistema para que cargue y reproduzca archivos `.wav` en lugar de `.mp3`:
>
> - Actualizar las rutas en `AppAudioService` y cualquier referencia en código o documentación.
> - Mantener la **misma estructura de carpetas** y la **misma lógica de asignación por contexto** (`Tap_sound`, `General_Tap`, `Level_Cleared`, `Movement_Not_Allowe`, `times_up`, `no_movements_left`, `background`).
> - Actualizar la tabla de referencia en `assets/audio/README.md`.
> - No modificar `IAudioService`, controladores ni la semántica de los métodos por contexto de UX.
> - Registrar la consulta en `AI_USAGE.md` con redacción técnica profesional.

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Asset WAV | Método en `IAudioService` | Contexto (sin cambios respecto a #30) |
|-----------|---------------------------|---------------------------------------|
| `background.wav` | `startBackgroundMusic()` / `stopBackgroundMusic()` | Música de fondo en bucle |
| `Tap_sound/tap_sound_1…5.wav` | `playArrowExtracted()` | Extracción exitosa de flecha (aleatorio) |
| `General_Tap/general_click_sound.wav` | `playButtonClick()` | Botones generales de la UI |
| `Level_Cleared/level_cleared.wav` | `playLevelCleared()` | Nivel completado |
| `Movement_Not_Allowe/not_allowed_movement.wav` | `playMovementNotAllowed()` | Colisión flecha–flecha |
| `times_up.wav` | `playTimeUp()` | Tiempo agotado |
| `no_movements_left.wav` | `playNoMovementsLeft()` | Movimientos agotados |

**Archivos modificados:**

| Archivo | Cambio |
|---------|--------|
| `lib/infrastructure/audio/app_audio_service.dart` | Constantes de ruta de `.mp3` → `.wav`; comentario de clase actualizado |
| `assets/audio/README.md` | Tabla de assets en formato WAV |
| `assets/audio/**` | Sustitución de archivos `.mp3` por `.wav` equivalentes (mismos nombres base) |

**Fragmento representativo:**

```dart
static const _backgroundMusic = 'audio/background.wav';
static const _timeUp = 'audio/times_up.wav';
static const _arrowExtractedSounds = [
  'audio/Tap_sound/tap_sound_1.wav',
  'audio/Tap_sound/tap_sound_2.wav',
  // ...
];
```

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Conversión masiva MP3 → WAV realizada por el equipo fuera del repositorio; los archivos `.wav` se colocaron en las mismas rutas relativas bajo `assets/audio/`.
- `pubspec.yaml` no requirió cambios: el directorio `assets/audio/` ya incluye todos los formatos hijos.

**Lecciones aprendidas o limitaciones identificadas.**

- La API de `audioplayers` (`AssetSource`) es agnóstica al contenedor; basta actualizar la ruta del asset — no hace falta cambiar `IAudioService` ni los controladores.
- WAV sin comprimir **aumenta el peso del bundle** respecto a MP3; conviene monitorizar el tamaño total de `assets/audio/` en builds Web y móvil.
- Tras sustituir assets de audio hace falta **restart completo** de la app; hot reload no recarga el bundle de assets.
- Centralizar rutas en constantes de `AppAudioService` evita regresiones al cambiar formato o nombre de archivo.
- En pruebas posteriores (Consulta #32), la migración a WAV resultó **problemática en Flutter Web (Brave/macOS)**: errores de reproducción y archivos WAV no estándar pueden fallar en el decodificador HTML5 del navegador.

---

## Consulta #32 — Reversión a MP3, corrección de carga en Web y mute acotado a música de fondo

**Tarea o problema abordado.**

Tras la migración a WAV (Consulta #31), la reproducción de audio falló en **Brave/macOS (Flutter Web)**: consola con `Uncaught Error` y/o HTTP **404** al cargar assets (`assets/assets/audio/...`). El equipo revirtió los archivos a **MP3**. Se requería: (1) restaurar todas las rutas `.wav` → `.mp3` en código y documentación; (2) endurecer la capa de reproducción para Web; (3) redefinir el toggle de **Mute** para que silencie **únicamente** `background.mp3`, manteniendo activos todos los efectos de juego (taps, clics, victoria, derrota, colisiones).

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura del repositorio, terminal y consola del navegador.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> He revertido los assets de audio a **MP3** (misma estructura de carpetas que antes). Realizar los siguientes cambios:
>
> - **Rutas y documentación:** sustituir todas las referencias a `.wav` por `.mp3` en `AppAudioService`, `assets/audio/README.md` y documentación relacionada.
> - **Reproducción robusta en Web:** corregir los errores de carga observados en consola (HTTP 404 con rutas duplicadas `assets/assets/...`); garantizar que los efectos y la música se reproduzcan de forma fiable en Flutter Web (Brave/macOS).
> - **Comportamiento del mute:** el interruptor de Ajustes debe silenciar **solo** la música de fondo (`background.mp3`). Los efectos de juego (`Tap_sound/`, `General_Tap/`, `Level_Cleared/`, `Movement_Not_Allowe/`, `times_up.mp3`, `no_movements_left.mp3`) deben seguir reproduciéndose con el mute activado.
> - **Arquitectura:** mantener `IAudioService`, `NoOpAudioService` para tests y la asignación por contexto de la Consulta #30.
> - Registrar la consulta en `AI_USAGE.md` con redacción técnica profesional.

**Resultado obtenido (fragmento de código, diseño, explicación).**

**Semántica del toggle de mute:**

| Asset MP3 | Método en `IAudioService` | ¿Afectado por mute? |
|-----------|---------------------------|---------------------|
| `background.mp3` | `startBackgroundMusic()` / `stopBackgroundMusic()` | **Sí** — se detiene al activar mute; se reanuda al desactivarlo |
| `Tap_sound/tap_sound_1…5.mp3` | `playArrowExtracted()` | **No** |
| `General_Tap/general_click_sound.mp3` | `playButtonClick()` | **No** |
| `Level_Cleared/level_cleared.mp3` | `playLevelCleared()` | **No** |
| `Movement_Not_Allowe/not_allowed_movement.mp3` | `playMovementNotAllowed()` | **No** |
| `times_up.mp3` | `playTimeUp()` | **No** |
| `no_movements_left.mp3` | `playNoMovementsLeft()` | **No** |

**Cambios técnicos en `AppAudioService` (iteración inicial):**

| Aspecto | Implementación |
|---------|----------------|
| Formato | Rutas `.mp3` restauradas en constantes |
| Carga Web | Primera iteración: `AssetSource('audio/...')` sin prefijo `assets/` — insuficiente en Brave; ver Consulta #33 |
| Efectos solapados | Pool rotativo de 3 `AudioPlayer` para SFX |
| Música de fondo | Reproductor dedicado; `startBackgroundMusic()` y `ensureAudioUnlocked()` respetan `isMuted` |
| Fallback nativo | `SystemSound` solo cuando `!kIsWeb` (no disponible en Web) |

**Integración con Ajustes y arranque:**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Toggle mute | `settings_screen.dart` | Persiste `isMuted` vía `AppSettingsController` |
| Reacción al mute | `main.dart` → `_onSettingsChanged()` | `stopBackgroundMusic()` si mute ON; `startBackgroundMusic()` si mute OFF |
| Etiqueta i18n | `app_strings.dart` | “Silenciar música de fondo” / “Mute background music” |
| Puertos | `i_app_settings.dart`, `i_audio_service.dart` | Documentación: `isMuted` aplica solo a BGM |

**Diagnóstico del error 404 en Web (iteración inicial):**

- Se probó `AssetSource('audio/...')` sin prefijo `assets/`, según documentación de `audioplayers`.
- En **Brave/macOS** persistieron HTTP **404** en `assets/assets/audio/...` y `MediaError: Format error (Code: 4)` (el navegador recibía HTML de error, no MP3).
- La **solución definitiva** se documenta en la Consulta #33 (`BytesSource` + claves del manifest + assets explícitos en `pubspec.yaml`).

**Archivos modificados:**

| Archivo | Cambio |
|---------|--------|
| `lib/infrastructure/audio/app_audio_service.dart` | MP3, `AssetSource` (iteración inicial), pool SFX, mute solo en BGM |
| `lib/application/ports/i_audio_service.dart` | Documentación de mute vs. efectos |
| `lib/application/ports/i_app_settings.dart` | `isMuted` = silencio de música de fondo |
| `lib/main.dart` | Stop/start de BGM al togglear mute |
| `lib/l10n/app_strings.dart` | Etiqueta “Silenciar música de fondo” |
| `lib/presentation/settings/settings_screen.dart` | Comentario de pantalla actualizado |
| `assets/audio/README.md` | Tabla MP3; nota sobre rutas relativas a `AssetSource` |

**Fragmento representativo (iteración inicial — sustituido en #33):**

```dart
Future<void> startBackgroundMusic() async {
  if (_settings.isMuted || _musicStarted) return;
  await _musicPlayer.play(AssetSource(_backgroundMusic)); // audio/background.mp3
}

Future<void> _playSfx(String assetPath, {SystemSoundType? fallback}) async {
  // Sin comprobación de isMuted — efectos siempre activos
  await player.play(AssetSource(assetPath));
}
```

**Modificaciones realizadas por el equipo al resultado de la IA.**

- El equipo revirtió manualmente los archivos de `assets/audio/` de WAV a MP3.
- Tras pruebas en Brave/macOS, se detectó que `AssetSource` seguía fallando; se abrió la Consulta #33.

**Lecciones aprendidas o limitaciones identificadas.**

- **MP3** sigue siendo el formato más compatible en navegadores para Flutter Web frente a WAV no estándar o de gran tamaño.
- `AssetSource` con rutas `audio/...` **no garantiza** reproducción en Flutter Web; puede seguir generando 404 con doble prefijo `assets/` (ver Consulta #33).
- Acotar el mute a la **música de fondo** permite al jugador silenciar el ambiente sin perder feedback sonoro del tablero (taps, victoria, derrota).
- Un pool de reproductores SFX evita condiciones de carrera al solapar sonidos consecutivos (`stop()` + `play()` en el mismo `AudioPlayer`).
- Tras cambiar assets o rutas: **`flutter clean`** + restart completo; hot reload no recarga el bundle.
- En Web, la política de **autoplay** sigue exigiendo un gesto del usuario antes de iniciar `background.mp3`; `ensureAudioUnlocked()` se invoca desde `withButtonClick` y `onCellTapped` (Consulta #30).

---

## Consulta #33 — Corrección definitiva de carga de audio en Flutter Web (BytesSource + manifest)

**Tarea o problema abordado.**

Tras la Consulta #32, la reproducción seguía fallando en **Brave/macOS (Flutter Web)**. La consola del navegador mostraba:

- Peticiones `GET` con HTTP **404** a rutas como `assets/assets/audio/General_Tap/general_click_sound.mp3`.
- Excepciones de `audioplayers`: `AudioPlayerException`, `WebAudioError`, `MediaError: MEDIA_ELEMENT_ERROR: Format error (Code: 4)` (efecto secundario del 404: el elemento `<audio>` recibe HTML de error, no un MP3).

Se requería una corrección definitiva que evite la resolución de URLs duplicadas de `AssetSource` en Web y garantice que todos los MP3 del juego estén empaquetados en el bundle.

**Herramienta de IA utilizada.**

- Cursor Agent (Composer), con acceso a lectura/escritura del repositorio, exploración de assets y consola del navegador.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Tras revertir los audios a MP3, en Flutter Web (Brave/macOS) los sonidos no se reproducen. La consola muestra errores HTTP 404 en rutas con doble prefijo `assets/assets/audio/...` y excepciones de `audioplayers` (`WebAudioError`, `Format error Code: 4`) al cargar archivos como `audio/General_Tap/general_click_sound.mp3`.
>
> Aplicar las correcciones recomendadas:
>
> - **Carga de assets:** usar `rootBundle.load()` con la clave exacta del manifest (`assets/audio/...`) y reproducir con `BytesSource` + `mimeType: audio/mpeg`, evitando peticiones HTTP fallidas de `AssetSource` en Web.
> - **Caché y pool:** mantener caché en memoria de bytes y pool rotativo de reproductores SFX para solapamiento de efectos.
> - **pubspec.yaml:** listar explícitamente los 11 archivos MP3 usados por el juego (más fiable en Web que solo declarar el directorio).
> - **Comportamiento del mute:** sin cambios respecto a #32 — el toggle silencia solo `background.mp3`; los efectos de juego siguen activos.
> - **Documentación:** actualizar `assets/audio/README.md` y registrar la consulta en `AI_USAGE.md` con redacción técnica profesional.

**Resultado obtenido (fragmento de código, diseño, explicación).**

**Estrategia de carga (Web y nativo):**

| Paso | Implementación |
|------|----------------|
| Clave del asset | Constantes con ruta completa del manifest: `assets/audio/General_Tap/general_click_sound.mp3` |
| Lectura | `rootBundle.load(bundleKey)` → `Uint8List` |
| Reproducción | `BytesSource(bytes, mimeType: 'audio/mpeg')` |
| Rendimiento | `Map<String, Future<Uint8List>>` como caché; pool de 3 `AudioPlayer` para SFX |

**Assets declarados explícitamente en `pubspec.yaml`:**

- `background.mp3`, `times_up.mp3`, `no_movements_left.mp3`
- `General_Tap/general_click_sound.mp3`
- `Level_Cleared/level_cleared.mp3`
- `Movement_Not_Allowe/not_allowed_movement.mp3`
- `Tap_sound/tap_sound_1.mp3` … `tap_sound_5.mp3`

**Semántica del mute (sin cambios respecto a #32):**

| Asset MP3 | ¿Afectado por mute? |
|-----------|---------------------|
| `background.mp3` | **Sí** |
| Resto de efectos de juego | **No** |

**Archivos modificados:**

| Archivo | Cambio |
|---------|--------|
| `lib/infrastructure/audio/app_audio_service.dart` | `BytesSource` + `rootBundle` + caché; claves `assets/audio/...` |
| `pubspec.yaml` | Listado explícito de 11 MP3 |
| `assets/audio/README.md` | Nota sobre carga vía manifest y `BytesSource` |

**Fragmento representativo:**

```dart
static const _generalTap =
    'assets/audio/General_Tap/general_click_sound.mp3';

Future<Uint8List> _loadAssetBytes(String bundleKey) {
  return _byteCache.putIfAbsent(bundleKey, () async {
    final data = await rootBundle.load(bundleKey);
    return data.buffer.asUint8List();
  });
}

await player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
```

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Validación en Brave/macOS tras `flutter clean`, `flutter pub get` y restart completo de la app (no hot reload).

**Lecciones aprendidas o limitaciones identificadas.**

- En Flutter Web, `AssetSource` puede generar URLs con doble prefijo `assets/`; el **404** es la causa raíz y el `Format error (Code: 4)` es un síntoma, no un códec corrupto.
- `rootBundle.load('assets/audio/...')` usa la clave correcta del manifest (un solo prefijo `assets/`).
- `BytesSource` reproduce desde memoria y evita la capa HTTP de `AudioCache` en Web.
- Listar assets **explícitamente** en `pubspec.yaml` reduce el riesgo de que archivos no entren al bundle Web tras cambios de formato o renombrado.
- Tras modificar assets o `pubspec`: **`flutter clean`** + restart completo obligatorio.

---

## Consulta #34 — Interruptor de silencio para efectos de victoria, derrota y flecha extraída

**Tarea o problema abordado.**

El equipo solicitó un segundo interruptor en la pantalla de Ajustes, independiente del mute de música de fondo ya existente, que permita silenciar específicamente los efectos de sonido de victoria (nivel completado), derrota (por movimientos o tiempo agotados) y flecha extraída del tablero, sin afectar el clic de botones ni el sonido de movimiento bloqueado.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, agente con acceso a terminal y sistema de archivos del repositorio.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Quiero un botón, que esté en la ventana "ajustes", el cual permita silenciar el juego, que los sonidos que ocurren cuando se gana, se pierde, una flecha sale del tablero, dejen de sonar. El botón de mute que ya existe déjalo y no lo modifiques.

**Resultado obtenido (fragmento de código, diseño, explicación).**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Puerto | `i_app_settings.dart` | `isEffectsMuted` / `setEffectsMuted(bool)`, independiente de `isMuted` |
| Persistencia | `shared_preferences_app_settings.dart` | Clave `settings_effects_muted` en `SharedPreferences` |
| En memoria | `in_memory_app_settings.dart` | Misma interfaz para tests |
| Controlador | `app_settings_controller.dart` | Expone `isEffectsMuted` / `setEffectsMuted` a la UI |
| UI | `settings_screen.dart` | Nuevo `SwitchListTile` (`key: settings-mute-effects`) bajo el mute existente, sin tocarlo |
| Audio | `app_audio_service.dart` | `playLevelCleared()`, `playNoMovementsLeft()`, `playTimeUp()` y `playArrowExtracted()` respetan el nuevo flag; `playButtonClick()` y `playMovementNotAllowed()` quedan fuera de su alcance |
| i18n | `app_strings.dart` | Etiquetas en inglés y español |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión del equipo tras el merge.

**Lecciones aprendidas o limitaciones identificadas.**

- Separar el mute de música de fondo del mute de efectos de resultado de partida en dos flags independientes evita acoplar preferencias de audio con semántica distinta (ambiente vs. feedback de juego).
- Delimitar explícitamente qué eventos de sonido quedan fuera del alcance de un nuevo control (clic de botones, movimiento bloqueado) previene que una función nueva silencie más de lo solicitado.

---

## Consulta #35 — Corrección de dos archivos de test que bloqueaban `flutter test`

**Tarea o problema abordado.**

Dos archivos de test fallaban en tiempo de análisis/compilación, impidiendo ejecutar la suite completa: `test/domain/level/level_time_limit_calculator_test.dart` y `test/interface_adapters/level_dto_mapper_test.dart`. Se solicitó diagnosticar la causa raíz de cada uno antes de aplicar cualquier corrección.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, agente con acceso a terminal, análisis estático (`flutter analyze`) y ejecución de la suite de tests.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Ahora necesito que resolvamos el problema de los 2 tests que están fallando; identifica qué pasa con esos tests primero.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Ambos archivos tenían defectos de naturaleza distinta, ninguno relacionado con lógica de dominio:

| Archivo | Causa raíz | Corrección |
|---------|-----------|------------|
| `level_time_limit_calculator_test.dart` | Un `Level` declarado `const` intentaba construirse reutilizando campos (`boardDefinition`, `playerStart`) de otro `Level` también `const` — el evaluador de expresiones constantes de Dart no permite leer el campo de una instancia `const` para componer otra expresión `const` en este caso, aunque el tipo sea inmutable. | Los objetos de prueba no necesitan ser constantes de compilación: se declararon como `final` en lugar de `const`. |
| `level_dto_mapper_test.dart` | Al bloque de test `should_map_display_name_from_wire_format` le seguía el cuerpo de otro caso de prueba **sin su envoltorio `test('...', () { ... })`** — probablemente perdido en una edición o fusión previa, dejando una sentencia suelta a nivel de `main()`. | Se restauró el envoltorio faltante con un nombre acorde al resto de la suite: `should_reject_level_when_optimal_moves_exceed_max_moves`. |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión del equipo tras el merge.

**Lecciones aprendidas o limitaciones identificadas.**

- Un mensaje de error del analizador de Dart puede parecer indicar un problema de tipos cuando en realidad es una restricción del evaluador de expresiones constantes; declarar los datos de prueba como `final` en vez de `const` evita la restricción sin perder ninguna garantía relevante para un test.
- Un `test(...)` faltante produce errores de compilación genéricos ("Expected a method, getter, setter...") que no señalan directamente el bloque anterior como causa; conviene revisar el archivo completo, no solo la línea reportada, ante errores de sintaxis inesperados en archivos de test.
- Diagnosticar antes de corregir (como se pidió explícitamente) evitó aplicar el mismo tipo de fix a dos problemas de naturaleza distinta.

---

## Consulta #36 — Tablero perdido al volver de Ajustes tras cambiar una preferencia durante la partida

**Tarea o problema abordado.**

Bug reportado por el equipo: al estar jugando un nivel, abrir Ajustes, activar el interruptor de silencio y volver atrás, la pantalla de juego quedaba mostrando un indicador de carga indefinido en lugar del tablero. El síntoma solo se reproducía al togglear una preferencia mientras la partida seguía activa detrás de Ajustes; no ocurría al entrar y salir de Ajustes sin tocar ningún control. Dado que la interacción directa con la app no era reproducible de forma fiable en el entorno de automatización disponible, el diagnóstico se realizó mediante un test de widgets construido para replicar la estructura exacta de navegación de `main.dart`.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, agente con acceso a terminal, ejecución de tests de widgets como método de reproducción determinística, y navegador para verificación visual complementaria.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Cuando estamos en un nivel y entramos a ajustes, cuando le damos al botón "atrás", el tablero ya no se ve. ¿Qué problema ocasiona eso? [Tras una primera hipótesis descartada por falta de reproducción directa:] Se ve así [tablero en blanco con spinner]. Esto solo ocurre si toco el botón de mute; si no lo hago, no hay problema alguno.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se construyó un test de widgets que reproduce la estructura real de `ArrowMazeApp` (un `StatefulWidget` raíz que escucha `AppSettingsController` y hace `setState({})` en cada cambio) para aislar el mecanismo exacto. Se confirmó que `MaterialPageRoute.builder` se reinvoca en **cada rebuild de cualquier ancestro del `Navigator`**, no una sola vez por navegación. Como `_onGenerateRoute` construía cada controlador de pantalla (`container.buildGameController()`, entre otros) **dentro** del `builder:`, cada rebuild del árbol — disparado por `notifyListeners()` al togglear cualquier ajuste — reemplazaba silenciosamente el `GameController` ya iniciado por uno nuevo y nunca iniciado, sin que `GameScreen` (sin `key` ni `didUpdateWidget`) lo notara.

| Componente | Ubicación | Cambio |
|------------|-----------|--------|
| Rutas afectadas | `main.dart` → `_onGenerateRoute` (`/game`, `/login`, `/register`, `/levels` ×2, `/leaderboard` ×2) | El controlador/caso de uso se construye una sola vez por navegación, **fuera** del `builder:`, capturado por closure |
| Test de regresión | `test/presentation/game/game_controller_survives_ancestor_rebuild_test.dart` | Reproduce el escenario exacto (push a Ajustes, disparo de un `ChangeNotifier`, `pop`) y falla sin el fix |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de verificación del equipo en su propio entorno (con audio funcional) antes del merge; el equipo confirmó el fix tras probarlo.

**Lecciones aprendidas o limitaciones identificadas.**

- `MaterialPageRoute.builder` no es una fábrica de un solo uso por navegación: se reinvoca en cada rebuild de cualquier ancestro del `Navigator`, incluido un `setState({})` en la raíz de la app. Cualquier dependencia construida dentro de ese `builder:` debe tratarse como potencialmente recreada en cualquier momento.
- Cuando la interacción manual con la UI no es reproducible de forma fiable (limitación del entorno de automatización), un test de widgets que reproduce la estructura real de navegación de la app es una vía de diagnóstico determinística y más rápida que iterar sobre hipótesis sin verificar.
- Confirmar un bug mediante un test que falla sin el fix y pasa con él (no solo mediante lectura de código) da mayor certeza de que la causa raíz identificada es la correcta.

---

## Consulta #37 — Cronómetro de partida congelado tras pausar y reanudar

**Tarea o problema abordado.**

El equipo reportó que el temporizador de la partida se detenía al entrar a Leaderboard o Ajustes durante el juego y no volvía a avanzar al regresar, dejando el tiempo restante fijo por el resto de la partida.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, agente con acceso a terminal y ejecución de tests de dominio.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Ahora hay otro bug: el tiempo se detiene al entrar en "leaderboard" o "ajustes" cuando estás jugando un nivel. Corrijámoslo.

**Resultado obtenido (fragmento de código, diseño, explicación).**

`Game.resume()` invocaba `copyWith(pausedAt: null, ...)` para limpiar la marca de pausa. Sin embargo, `copyWith` resuelve cada parámetro nulo opcional con el patrón `pausedAt ?? this.pausedAt`, por lo que pasar `null` explícitamente nunca sobrescribe el valor anterior — `copyWith` ya exponía un flag `clearPausedAt` pensado exactamente para este caso, que `resume()` no utilizaba. Efecto: tras el primer ciclo de pausa/reanudación, la resta de "tiempo en pausa" en `elapsedSeconds` crecía al mismo ritmo que el tiempo real transcurrido, cancelándose exactamente y congelando el cronómetro para el resto de la partida.

```dart
// Antes (bug): `pausedAt: null` nunca limpia el campo vía `copyWith`.
return copyWith(
  status: GameStatus.inProgress,
  pausedAt: null,
  totalPausedDuration: totalPausedDuration + now.difference(pauseStarted),
);

// Después: usa el flag que copyWith ya exponía para este caso.
return copyWith(
  status: GameStatus.inProgress,
  clearPausedAt: true,
  totalPausedDuration: totalPausedDuration + now.difference(pauseStarted),
);
```

| Componente | Ubicación | Cambio |
|------------|-----------|--------|
| Dominio | `lib/domain/game/aggregates/game.dart` → `Game.resume()` | `pausedAt: null` → `clearPausedAt: true` |
| Tests | `test/domain/game/game_test.dart` | `should_clear_pausedAt_after_resume`, `should_not_double_subtract_pause_duration_after_resume` |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- El equipo verificó el fix en su propio entorno (Windows, con audio funcional) y confirmó que el cronómetro ya avanza correctamente tras volver de Ajustes o Leaderboard.

**Lecciones aprendidas o limitaciones identificadas.**

- El patrón `campo: parámetro ?? this.campo` en un `copyWith` no puede limpiar un campo nulable pasando `null` explícitamente, porque `null ?? this.campo` siempre resuelve al valor previo; se necesita un flag dedicado (`clearCampo: true`) para ese caso, y debe usarse consistentemente en todo el dominio.
- Verificar un fix de temporización con un test que falla sin él (reproduciendo el estado exacto: pausado con `pausedAt` fijo) es más confiable que inspeccionar el código a simple vista, dado que el efecto (congelamiento) solo se manifiesta al combinar dos términos que se cancelan algebraicamente con el paso del tiempo real.

---

## Consulta #38 — Ampliación del alcance del interruptor de silencio de efectos

**Tarea o problema abordado.**

El interruptor de silencio de efectos introducido en la Consulta #34 solo cubría los sonidos de victoria, derrota y flecha extraída. El equipo identificó que aún quedaban acciones que producían sonido con el interruptor activado: el clic de botones generales de la interfaz y el sonido de movimiento bloqueado. Se solicitó ampliar el alcance del control para que silencie la totalidad de los efectos de sonido del juego, dejando intacta la música de fondo y el interruptor que la gobierna.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, agente con acceso a terminal y sistema de archivos del repositorio.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Ahora necesito modifiques lo que hace el botón de mute que hicimos. Quiero que ese botón silencie todo el sonido que no es el de background music; hay acciones que todavía generan sonido.

**Resultado obtenido (fragmento de código, diseño, explicación).**

La comprobación de `isEffectsMuted`, antes duplicada en cada método público que reproducía un efecto, se centralizó en el helper privado `_playSfx()` que todos ellos comparten. De este modo, cualquier efecto que se agregue a futuro a través de ese helper queda cubierto por el interruptor sin necesidad de repetir la condición.

```dart
// Antes: la comprobación solo estaba en algunos métodos (victoria, derrota,
// flecha extraída); playButtonClick() y playMovementNotAllowed() sonaban siempre.
Future<void> playLevelCleared() async {
  if (_settings.isEffectsMuted) return;
  await _playSfx(_levelCleared);
}

// Después: un único punto de control en el helper compartido.
Future<void> _playSfx(String bundleKey, {SystemSoundType? fallback}) async {
  if (_settings.isEffectsMuted) return;
  // ... carga y reproducción del efecto
}
```

| Componente | Ubicación | Cambio |
|------------|-----------|--------|
| Audio | `lib/infrastructure/audio/app_audio_service.dart` | Comprobación de `isEffectsMuted` centralizada en `_playSfx()`; retirada de los métodos públicos individuales |
| Puertos | `i_app_settings.dart`, `i_audio_service.dart` | Documentación actualizada: `isEffectsMuted` cubre todos los efectos, no solo resultado de partida |
| Controlador y persistencia | `app_settings_controller.dart`, `shared_preferences_app_settings.dart`, `in_memory_app_settings.dart` | Comentarios de documentación alineados con el nuevo alcance |
| i18n | `app_strings.dart` | Etiqueta actualizada a "Mute all sound effects" / "Silenciar todos los efectos de sonido" |
| UI | `settings_screen.dart` | Comentario de pantalla actualizado |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de verificación del equipo, dado que la sesión de desarrollo se realizó en macOS, entorno donde la reproducción de audio no pudo confirmarse de forma directa (ver limitaciones de audio en Flutter Web documentadas en consultas previas).

**Lecciones aprendidas o limitaciones identificadas.**

- Centralizar una regla transversal (como un flag de silencio) en el punto único por el que pasan todas las llamadas afectadas, en lugar de repetirla en cada método público, evita que una nueva función de audio quede fuera de su alcance por omisión.
- Cuando el entorno de desarrollo no coincide con el de prueba final del equipo (macOS vs. Windows, en este caso), la verificación funcional del comportamiento de audio queda pendiente de confirmación por quienes sí pueden reproducirlo, y así debe quedar explícito en la documentación.

---

## Consulta #39 — Extensión de pruebas de contrato a auth, progress y leaderboard (sin Pact)

**Tarea o problema abordado.**

El enunciado del proyecto recomienda explícitamente usar **Pact** (o herramienta equivalente) para pruebas de contrato consumer-driven entre el cliente del juego y el backend. Ya existía una prueba de contrato para el DTO de nivel (fixture compartido `docs/levels/simple-1.json`), pero cubría solo una de las cinco fronteras HTTP que este repo comparte con el backend. Se solicitó extender el mismo patrón a `POST /auth/register`, `POST /auth/login`, `POST /progress/sync` (request y response), `GET /progress` y `GET /leaderboard/:levelId`, explícitamente sin adoptar Pact, y documentar el razonamiento.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5. La decisión de no usar Pact se validó investigando primero el estado real de su soporte para Dart/Flutter (sin SDK de consumidor oficial ni bien mantenido); la extensión del patrón se diseñó en modo de planificación con aprobación explícita antes de implementar, y se ejecutó de forma simétrica en ambos repos (backend y frontend).

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> [Sobre la recomendación de Pact del enunciado, mostrando la captura de la rúbrica:] ¿Debo aplicar esto según el enunciado del proyecto? ¿Crees que lo estamos cumpliendo según lo realizado, o hay que mejorarlo? [Tras la evaluación, con la brecha identificada:] Estoy de acuerdo, aplícalo a todos los endpoints compartidos como estás sugiriendo, sin la necesidad de usar Pact. Agrega ese razonamiento en la documentación.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se agregaron seis fixtures JSON compartidos con el backend (bit-a-bit idénticos en ambos repos) bajo `docs/contract/fixtures/`, con una prueba en este repo por cada fixture que ejercita el **cliente HTTP real** (no una re-implementación de su forma), usando el `MockHttpClient` existente que reenvía la petición real al handler de prueba.

```dart
// El cliente HTTP REAL debe parsear el fixture de respuesta en el modelo esperado.
final client = MockHttpClient((request) async => http.Response(jsonEncode(fixture), 200));
final api = AuthApiClient(config: config, httpClient: client);
final session = await api.login(username: 'ignored', password: 'ignored12');
expect(session.token, fixture['token']);

// Para el request de sync, se captura el cuerpo REAL enviado por el cliente
// y se compara contra el fixture compartido.
final client = MockHttpClient((request) async {
  sentBody = jsonDecode(request.body) as Map<String, dynamic>;
  return http.Response('{}', 200);
});
// ...
expect(sentBody, fixture);
```

| Componente | Ubicación | Rol |
|------------|-----------|-----|
| Fixtures | `docs/contract/fixtures/*.json` (6 archivos, idénticos al backend) | Forma compartida de cada frontera HTTP |
| Razonamiento documentado | `docs/contract/fixtures/README.md` | Por qué fixtures compartidos en vez de Pact, y la limitación aceptada |
| Prueba de contrato | `test/infrastructure/http/contract_fixtures_test.dart` | `AuthApiClient`, `ProgressApiClient` y `LeaderboardApiClient` reales parseando cada fixture de respuesta; el body real de `syncProgress()` comparado contra el fixture de request |

Nota: `progress-sync-response.json` no se ejercita en este repo porque `ProgressApiClient.syncProgress()` descarta el cuerpo de esa respuesta (devuelve `void`) una vez confirma el 200; ese fixture lo verifica el backend, que sí produce y necesita mantener esa forma.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con `flutter analyze` y `flutter test` (104/104 tests) en este repo, y con `npm run lint`, `npm run build` y `npm test` (169/169 tests) en el backend, antes de commitear.

**Lecciones aprendidas o limitaciones identificadas.**

- No toda recomendación de la rúbrica aplica igual de bien a cualquier stack: Pact tiene soporte maduro para JVM/.NET/JS/Python/Go/Ruby, pero no para Dart/Flutter en el lado consumidor, lo que lo vuelve poco práctico como "primera opción" para este proyecto sin construir tooling propio desproporcionado al alcance.
- Una prueba de contrato no necesita un framework dedicado para dar la garantía central que importa (que ambos lados coinciden en la forma de los datos): un fixture compartido más pruebas que ejercitan el cliente HTTP real de cada endpoint logra el mismo objetivo, al precio de sincronización manual entre repos en vez de automática.
- Cuando un cliente descarta deliberadamente el cuerpo de una respuesta (como `syncProgress()`), no tiene sentido forzar una prueba de contrato sobre esa forma en este lado; documentar explícitamente por qué (en vez de omitirlo en silencio) evita que parezca una omisión no intencional.

---

## Consulta #40 — Fixture de `GET /levels`, fixtures de error y verificación de sincronización en CI

**Tarea o problema abordado.**

Como refinamiento sobre la extensión de pruebas de contrato (Consulta #39), se pidieron cuatro mejoras: (1) un fixture compartido para `GET /levels` (un nivel de ejemplo del catálogo); (2) validación de tipos con Zod del lado del backend (no aplica a este repo, que usa su propio sistema de tipos de Dart — ver detalle abajo); (3) fixtures para los errores 401 y 409; (4) un script o chequeo en CI que compare los fixtures de contrato entre los dos repos por hash.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal con acceso de lectura/escritura al repositorio, ejecución de `flutter test`/`flutter analyze` y del script de sincronización (incluyendo una prueba deliberada de divergencia en el repo backend para confirmar que el script sí falla cuando corresponde).

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Ahora: añadir fixture compartido para `GET /levels` (un nivel de ejemplo del catálogo). Validar tipos además de claves en el backend (p. ej. con Zod schemas para respuestas, no solo requests). Añadir fixtures de error: 401 Unauthorized, 409 UserAlreadyExists. Script o check en CI que compare hashes de fixtures entre repos (aunque sean repos separados).

**Resultado obtenido (fragmento de código, diseño, explicación).**

```dart
// El cliente HTTP REAL (LevelApiClient) y el mapper REAL (LevelDtoMapper)
// procesan el fixture de punta a punta, no una re-implementación de su forma.
final rawLevels = await api.fetchAllLevels();
final levels = rawLevels.map(mapper.fromJson).toList();
expect(levels.first.id.value, expected['id']);
```

```dart
// El error 401/409 se valida a través de la excepción REAL que lanza el cliente.
await expectLater(
  api.login(username: 'ignored', password: 'ignored12'),
  throwsA(isA<ApiException>()
      .having((e) => e.statusCode, 'statusCode', 401)
      .having((e) => e.message, 'message', (fixture['error'] as Map)['message'])),
);
```

| Componente | Ubicación | Cambio |
|------------|-----------|--------|
| Fixtures nuevos | `docs/contract/fixtures/levels-get-response.json`, `error-401-unauthorized.json`, `error-409-user-already-exists.json` | Idénticos a los del repo backend |
| Prueba de contrato | `test/infrastructure/http/contract_fixtures_test.dart` | Nuevo grupo para `LevelApiClient`/`LevelDtoMapper` contra `GET /levels`; nuevo grupo para el sobre de error 401/409 vía `ApiException` |
| Script de sincronización | `scripts/check-contract-fixtures-sync.sh` | Compara SHA-256 de cada fixture contra el repo backend (checkout hermano en local, clon superficial en CI); falla solo ante una divergencia real de contenido |
| CI | `.github/workflows/ci.yml` | Nuevo paso que corre el script tras `flutter test` |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con `flutter analyze` y `flutter test` (108/108 tests) en este repo, y con `npm run lint`, `npm run build` y `npm test` (172/172 tests) en el backend, antes de commitear.

**Lecciones aprendidas o limitaciones identificadas.**

- La validación de tipos con Zod pedida en el punto 2 es específica del backend (Node/TypeScript, sin chequeo de tipos en runtime propio); este repo ya valida tipos implícitamente en cada parseo (`json['highScore'] as int`, etc. lanza en runtime si el tipo no coincide) como parte de sus propios modelos, así que no había un gap equivalente que cerrar aquí — se documenta explícitamente para que no parezca una omisión.
- Verificar la excepción real que lanza un cliente HTTP ante un error (en vez de solo inspeccionar el parseo del cuerpo) confirma que el `statusCode` y el `message` observables por quien use el cliente coinciden con el contrato, no solo que el JSON se parsea correctamente.
- Un chequeo de sincronización entre dos repos independientes en CI debe decidir explícitamente qué hacer cuando no puede acceder al otro repo (privado, sin red): reportarlo sin fallar el build es el comportamiento correcto para una red de seguridad adicional, no un gate obligatorio.

## Consulta #41 — Mensajes de derrota hardcodeados en español y diagnóstico del nombre genérico en el catálogo

**Tarea o problema abordado.**

El usuario reportó que, con el idioma de la app en inglés, el diálogo de derrota mostraba el título correctamente localizado ("Level failed") pero el mensaje del cuerpo aparecía siempre en español (p. ej. "Has superado el número máximo de movimientos permitidos. ¡Has perdido!"), tanto al agotar movimientos como al agotar el tiempo. También reportó que el catálogo de niveles mostraba un nombre genérico ("Nivel N") en vez del nombre propio de algunos niveles.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal con acceso de lectura/escritura al repositorio y al repositorio backend, y ejecución de `flutter analyze`/`flutter test`.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Cuando el idioma es en inglés, los errores se muestran en español, ejemplo cuando se acaba el tiempo o los intentos, corrígelo por favor. También corrige que los idiomas mostrados en el catálogo de niveles en la app, sean nombres propios y no un nombre genérico que digan "nivel 1".

**Resultado obtenido (fragmento de código, diseño, explicación).**

Diagnóstico del primer problema: `GameLossMessage` (`lib/domain/game/value_objects/game_loss_message.dart`) transportaba el texto final ya redactado en español como constante de dominio, en vez de solo el motivo de la derrota — por eso ignoraba el locale activo. Se refactorizó para transportar únicamente un `enum GameLossReason` (`movesExceeded`/`timeExceeded`), y se resolvió el texto localizado en la capa de presentación:

```dart
// lib/presentation/result/defeat_screen.dart
final lossText = switch (args.game.lossMessage?.reason) {
  GameLossReason.movesExceeded => strings.defeatMovesExceededMessage,
  GameLossReason.timeExceeded => strings.defeatTimeExceededMessage,
  null => strings.defeatMessage,
};
```

Se agregaron las claves `defeatMovesExceededMessage`/`defeatTimeExceededMessage` a `AppStrings` (`lib/l10n/app_strings.dart`), con su traducción en `AppStringsEn` y `AppStringsEs`.

Diagnóstico del segundo problema (nombre genérico en el catálogo): se auditó el código real antes de tocar nada. `level_select_screen.dart` ya usa `level.displayLabel`, que en `lib/domain/level/aggregates/level.dart` prioriza `displayName` (mapeado desde el campo `name` del DTO) y solo cae al `id` (p. ej. `"level-21"`) si `displayName` viene vacío — **no** hay ningún lugar del código que sintetice un texto genérico tipo `"Nivel N"`. Al revisar el catálogo real del backend (`BackEnd-ArrowMaze/levels/*.json`), se confirmó que `level-21.json` y `level-22.json` eran los únicos dos de 22 archivos sin campo `"name"` — por eso mostraban su id crudo en vez de un título. Se corrigió agregando `"name": "Simetría Perfecta"` y `"name": "Todos los Tamaños"` respectivamente, en el repo backend.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con `flutter analyze` (sin nuevas advertencias) y `flutter test` (107/107 tests, incluyendo `defeat_screen_test.dart`) en este repo, y con `npm run lint`, `npm run build` y `npm test` (172/172 tests) en el backend tras agregar los nombres faltantes.

**Lecciones aprendidas o limitaciones identificadas.**

- Un mensaje de error "traducido" que en realidad es una constante de texto fijo en la capa de dominio es un bug de localización parcial fácil de pasar por alto, porque el resto de la pantalla (título, botones) sí se ve correctamente traducido — hay que revisar explícitamente el origen de cada string mostrado al usuario, no solo la pantalla como un todo.
- Antes de asumir que un síntoma reportado por el usuario es un bug de código, vale la pena confirmar dónde vive realmente el dato: en este caso el código de presentación ya estaba bien diseñado (prioriza nombre propio, cae a un identificador solo como último recurso) y el síntoma real era un vacío de datos en el catálogo del backend, no un defecto del frontend.

## Consulta #42 — Mismo bug de localización en la pantalla de clasificación (leaderboard)

**Tarea o problema abordado.**

El usuario reportó, con una captura de pantalla, que la pantalla de clasificación mostraba el título correctamente en español ("Clasificación — Primer C...") pero el subtítulo de cada entrada del ranking ("Score: 300 · Moves: 3 · Time: 3s") seguía en inglés — el mismo patrón de bug corregido en la Consulta #41 para la pantalla de derrota, pero en un lugar distinto del código.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal con acceso de lectura/escritura al repositorio, ejecución de `flutter analyze`/`flutter test`, y un intento de verificación visual en el navegador embebido (no concluyente por limitaciones de interacción con el canvas de Flutter Web sin árbol de accesibilidad; se optó por una prueba de widget automatizada como evidencia en su lugar).

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> El leaderboard muestra todo en inglés aun cuando el idioma elegido es español.

**Resultado obtenido (fragmento de código, diseño, explicación).**

`grep` localizó el origen exacto: `lib/presentation/leaderboard/leaderboard_screen.dart:73` interpolaba el subtítulo directamente en inglés (`'Score: ${entry.highScore} · Moves: ${entry.minMoves} · Time: ${entry.minTimeInSeconds}s'`) sin pasar por `AppStrings`. Se agregó el método localizado `leaderboardEntrySubtitle({score, moves, timeInSeconds})` a `AppStrings`/`AppStringsEn`/`AppStringsEs`, y se reemplazó la interpolación directa por la llamada al método:

```dart
subtitle: Text(
  strings.leaderboardEntrySubtitle(
    score: entry.highScore,
    moves: entry.minMoves,
    timeInSeconds: entry.minTimeInSeconds,
  ),
),
```

Se agregó cobertura de test explícita para ambos locales en `test/presentation/leaderboard/leaderboard_screen_test.dart` (uno ya existente reforzado con la aserción en inglés, y uno nuevo `should_show_entry_subtitle_in_spanish_when_locale_is_spanish`), siguiendo el mismo patrón que ya usaba `defeat_screen_test.dart` para el mensaje de derrota.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con `flutter analyze` (sin nuevas advertencias) y `flutter test` (108/108 tests, incluyendo los 2 casos nuevos/reforzados de `leaderboard_screen_test.dart`).

**Lecciones aprendidas o limitaciones identificadas.**

- Un mismo defecto de localización (texto final hardcodeado en vez de resuelto vía `AppStrings`) puede repetirse en más de una pantalla de forma independiente; conviene, tras corregir el primer caso, buscar el mismo patrón (`grep` por literales en inglés/español fuera de `app_strings.dart`) en el resto de la presentación en vez de asumir que era un caso aislado.
- Verificar un fix de localización interactuando con la UI en el navegador embebido no siempre es viable: Flutter Web sin árbol de semántica no expone los widgets al DOM, así que los clics por coordenada pueden no alcanzar el widget esperado. Una prueba de widget que monta la pantalla con `AppStringsEs`/`AppStringsEn` explícitos y verifica el texto exacto es una verificación más confiable — y queda como regresión permanente — que una captura de pantalla puntual.

## Consulta #43 — Auditoría completa de textos hardcodeados sin localizar

**Tarea o problema abordado.**

Tras corregir dos casos puntuales de este mismo bug (Consultas #41 y #42), el usuario pidió revisar de forma sistemática si el mismo problema (texto final de UI hardcodeado en un idioma fijo, sin pasar por `AppStrings`) ocurría en algún otro lugar de la app.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, con un subagente de exploración (`Explore`) dedicado a auditar `lib/` en busca de literales de texto de UI fuera de `app_strings.dart`, seguido de la implementación y verificación en la sesión principal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Podrías revisar dónde más puede estar ocurriendo.

**Resultado obtenido (fragmento de código, diseño, explicación).**

La auditoría encontró tres focos adicionales, confirmados y corregidos:

1. **`lib/presentation/auth/login_screen.dart` y `register_screen.dart`** (el de mayor visibilidad: toda la pantalla de login/registro estaba en inglés fijo salvo el mensaje de error, que ya usaba `authErrorMessage`). Título del AppBar, etiquetas de campo (`Username`/`Password`), errores de validación (`Min 3 characters`, `Required`, `Min 8 characters`), y botones (`Sign in`, `Create account`, `Already have an account? Sign in`) estaban todos hardcodeados. Se agregaron 11 claves nuevas a `AppStrings` (`loginTitle`, `registerTitle`, `usernameLabel`, `passwordLabel`, `passwordMinLengthLabel`, `requiredFieldError`, `minUsernameLengthError`, `minPasswordLengthError`, `createAccount`, `alreadyHaveAccountSignIn`) con su traducción en/es, y ambas pantallas ahora leen todo de `AppStringsScope.of(context)`.
2. **`lib/presentation/level_select/level_select_screen.dart:144`** — el catálogo vacío mostraba `'No levels available.'` fijo. Se agregó `levelSelectNoLevels`.
3. **`lib/presentation/level_select/level_select_screen.dart:139`** — el error de carga inicial del catálogo mostraba `'${widget.controller.error}'`, el `toString()` crudo de la excepción (mismo patrón que `GameLossMessage` en la Consulta #41: un valor de dominio con su mensaje final ya redactado, ignorando el locale). Se reemplazó por `strings.levelSelectLoadFailed`, un mensaje genérico localizado, igual que ya hacía la pantalla de leaderboard para su caso análogo.

Se agregó cobertura de test explícita en/es para los tres casos (`login_screen_test.dart`, `register_screen_test.dart`, `level_select_screen_test.dart`).

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con `flutter analyze` (sin nuevas advertencias) y `flutter test` (112/112 tests, incluyendo los 4 casos nuevos).

**Lecciones aprendidas o limitaciones identificadas.**

- Una auditoría dirigida por subagente, acotada explícitamente al patrón de bug ya conocido (texto de UI final fuera de `AppStrings`) y con instrucciones de ignorar ruido (logs, excepciones no mostradas, comentarios), es más efectiva que repetir manualmente el mismo `grep` puntual: encontró tanto literales obvios (`Text('...')`) como una variante más sutil (un `toString()` de excepción de dominio renderizado directo), que un grep de texto simple no habría relacionado sin ese contexto.
- Las pantallas de autenticación (login/registro) son las de mayor exposición real para este tipo de bug — todo usuario no autenticado las ve — y sin embargo habían quedado fuera de las dos correcciones anteriores porque el síntoma reportado por el usuario apuntaba a otras pantallas; vale la pena, tras el primer hallazgo de un patrón de bug, preguntar explícitamente "¿dónde más puede estar pasando esto?" en vez de darlo por cerrado con el caso puntual reportado.

## Consulta #44 — Toggle opcional de cuadrícula en la pantalla de juego

**Tarea o problema abordado.**

Se solicitó añadir en la pantalla de partida un control discreto que permita al jugador activar o desactivar la visualización de la cuadrícula (grid) sobre el tablero, como ayuda visual durante el juego, sin alterar la lógica de partida ni el resto del sistema.

**Herramienta de IA utilizada.**

- Cursor (Composer), sesión interactiva con acceso de lectura/escritura al repositorio del cliente Flutter.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> ¿Es viable añadir en la pantalla de juego un botón compacto que permita mostrar u ocultar la cuadrícula (grid) sobre el tablero mientras se juega un nivel?
>
> Implementar ese botón de toggle de cuadrícula activable durante la partida. El cambio debe limitarse exclusivamente a la capa de presentación de la vista del board (renderizado visual); no debe interferir con dominio, casos de uso, persistencia, backend ni otras pantallas del flujo.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se añadió un estado local `_showGrid` en `BoardView` (sin persistencia en `SharedPreferences` ni en `IAppSettings`), un botón overlay (`ValueKey('board-grid-toggle')`) en la esquina superior derecha del tablero, y el parámetro `showGrid` en `ArrowBoardPainter` para dibujar líneas con `AppColors.gridLine` debajo de muros y flechas. Se agregaron tooltips localizados (`showGridTooltip` / `hideGridTooltip`) en `AppStrings`. La capa de toques (`_BoardTouchGrid`) quedó intacta.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- La ubicación inicial del botón (overlay en la esquina superior derecha del tablero) se refinó en la Consulta #45, moviéndolo al HUD junto a la fila de puntuación.

**Lecciones aprendidas o limitaciones identificadas.**

- Preferencias puramente visuales y efímeras (solo durante la partida) pueden resolverse con estado local en el widget de presentación, evitando extender `IAppSettings` o el backend cuando no hay requisito de persistencia entre sesiones.

## Consulta #45 — Reubicación del toggle de cuadrícula al HUD de puntuación

**Tarea o problema abordado.**

Tras implementar el toggle de cuadrícula (Consulta #44), el usuario reportó con captura de pantalla que el botón quedaba **dentro** del área del tablero (overlay sobre la cuadrícula) y solicitó moverlo **fuera** del board, cerca de la línea donde se muestran movimientos y puntuación.

**Herramienta de IA utilizada.**

- Cursor (Composer), sesión interactiva con acceso de lectura/escritura al repositorio del cliente Flutter.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Reubicar el botón de toggle de cuadrícula para que quede fuera del área del tablero y, en su lugar, junto a la fila del HUD donde se muestra la puntuación (movimientos y score).

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se movió el estado `_showGrid` de `BoardView` a `GameScreen` y se extrajo el widget reutilizable `BoardGridToggleButton`. El HUD de partida ahora usa un `Row`: texto de movimientos/puntuación a la izquierda y el botón de grid a la derecha; el tiempo permanece en la línea inferior. `BoardView` volvió a ser `StatelessWidget` y solo recibe `showGrid` como parámetro para `ArrowBoardPainter`.

**Archivos modificados:**

| Archivo | Cambio |
|---------|--------|
| `lib/presentation/game/game_screen.dart` | Estado `_showGrid` y `BoardGridToggleButton` en el HUD |
| `lib/presentation/game/widgets/board_view.dart` | Eliminado overlay del botón; exportado `BoardGridToggleButton` |

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión manual del equipo.

**Lecciones aprendidas o limitaciones identificadas.**

- Controles de UI que afectan la vista del tablero pero no son parte del juego en sí encajan mejor en el HUD externo que como overlay sobre el área de juego: evitan tapar celdas y mejoran la legibilidad en tableros pequeños o densos.

## Consulta #46 — Sistema de coleccionables meta con galería de emojis

**Tarea o problema abordado.**

Se solicitó implementar un sistema de **coleccionables meta** desbloqueables al avanzar en la secuencia de niveles, y posteriormente enriquecer su presentación visual con una hoja de sprites de emojis, integración en la navegación global y flujos de interacción en victoria y galería.

**Herramienta de IA utilizada.**

- Cursor (Composer), sesión interactiva con acceso de lectura/escritura al repositorio del cliente Flutter.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Implementar un sistema de coleccionables meta que se desbloqueen al completar cada nivel par de la secuencia (2, 4, 6, …) con desempeño perfecto: 3 estrellas y puntuación completa del nivel. Persistir el progreso de desbloqueo localmente junto al resto de [PlayerProgress].
>
> Extender la experiencia visual e interactiva de los coleccionables: añadir un botón de acceso con el mismo patrón de [AppNavActions] que el de clasificación; mostrar en la pantalla de galería los emojis de la hoja de sprites provista (cuadrícula 7×7, excluyendo la última columna de botones UI); mostrar el emoji desbloqueado en la pantalla de victoria cuando se cumplan los criterios; al pulsar el anuncio de victoria, navegar a la galería de coleccionables; y al pulsar un emoji en la galería, abrir una vista ampliada del coleccionable.

**Resultado obtenido (fragmento de código, diseño, explicación).**

**Fase 1 — Lógica de dominio y desbloqueo**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| `MetaCollectible` | `lib/domain/progress/value_objects/meta_collectible.dart` | Identificador, hito de nivel y `spriteIndex` |
| `MetaCollectibleCatalog` | `lib/domain/progress/services/meta_collectible_catalog.dart` | 11 hitos (niveles pares 2–22) |
| `MetaCollectibleUnlockPolicy` | `lib/domain/progress/services/meta_collectible_unlock_policy.dart` | Valida nivel par + 3 estrellas + score máximo |
| `PlayerProgress.unlockedCollectibles` | `lib/domain/progress/aggregates/player_progress.dart` | Set persistido de IDs desbloqueados |
| `RecordVictoryUseCase` | `lib/application/use_cases/record_victory_use_case.dart` | Otorga coleccionable y expone `newlyUnlockedCollectible` |

**Fase 2 — Presentación con sprites e interacción**

| Componente | Ubicación | Responsabilidad |
|------------|-----------|-----------------|
| Sprite sheet | `assets/images/collectibles_sheet.png` | Hoja 8×7; galería usa columnas 1–7 (49 emojis) |
| `CollectibleSpriteImage` | `lib/presentation/collectibles/collectible_sprite_image.dart` | Recorte de celda + diálogo ampliado |
| `CollectiblesScreen` | `lib/presentation/collectibles/collectibles_screen.dart` | Grid 7×7; toque abre vista ampliada |
| `AppNavActions` | `lib/presentation/widgets/app_nav_actions.dart` | Botón de coleccionables (mismo patrón que leaderboard) |
| `VictoryScreen` | `lib/presentation/result/victory_screen.dart` | Anuncio con emoji; toque navega a `/collectibles` |
| `AppStrings` | `lib/l10n/app_strings.dart` | Nombres, requisitos y mensajes en/es |

**Regla de desbloqueo aplicada:**

- Nivel par (`levelNumber % 2 == 0`) + `StarRating.three` + `score >= maxScoreForLevel`.
- Los coleccionables se persisten solo en cliente (como las estrellas); no se sincronizan con el backend.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de revisión manual del equipo.

**Lecciones aprendidas o limitaciones identificadas.**

- Los metadatos de desempeño fino (estrellas) y las recompensas cosméticas (coleccionables) pueden vivir en `PlayerProgress` local sin extender el contrato REST mientras no haya requisito de sincronización multi-dispositivo — el mismo patrón ya usado para `bestStars`.
- Una hoja de sprites compartida simplifica la galería (49 slots visuales) frente a 49 assets sueltos, pero exige mapear explícitamente qué índices son desbloqueables (11 hitos) vs. slots solo visuales bloqueados (38 restantes).
- Unificar el acceso en `AppNavActions` evita botones ad hoc por pantalla y mantiene coherencia con clasificación y ajustes.

## Consulta #47 — Revisión de tests y sincronización de fixtures de contrato (CI)

**Tarea o problema abordado.**

Tras integrar el sistema de coleccionables con sincronización en backend, el pipeline de GitHub Actions del repositorio **BackEnd-ArrowMaze** falló en el job `build-test`, paso **"Verify contract fixtures match the frontend repo"**: el fixture `docs/contract/fixtures/progress-get-response.json` divergía entre backend y frontend (el backend ya incluía `collectibles`; el frontend remoto no). Se solicitó revisar todo el proyecto en materia de tests y corregir los fallos detectados (para este cambio por conflictos que se dieron por un detalle de Internet entre el Github).

**Herramienta de IA utilizada.**

- Cursor (Composer), sesión interactiva con acceso de lectura/escritura a los repositorios **Arrow-Maze-Escape-Puzzle** (Flutter) y **BackEnd-ArrowMaze** (Node/Express).

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> revisa todo el Proyecto en cuestion de test y resuelve estos problemas que estan sucediendo

*(Contexto adjunto: captura del CI fallido en `Georopeza/BackEnd-ArrowMaze`, job `build-test`, fixture divergente `progress-get-response.json` entre backend y frontend.)*

**Resultado obtenido (fragmento de código, diseño, explicación).**

**Correcciones aplicadas:**

| Área | Archivo | Cambio |
|------|---------|--------|
| Contrato compartido | `docs/contract/fixtures/progress-get-response.json` | Añadido `"collectibles": ["collectible-milestone-2"]` para alinear con el backend |
| Tests de contrato | `test/infrastructure/http/contract_fixtures_test.dart` | Actualizado para validar `RemotePlayerProgress` (`.levels` + `.collectibles`) en lugar de una lista plana de niveles |
| UI / E2E | `lib/presentation/result/victory_screen.dart` | Contenido envuelto en `SingleChildScrollView` para evitar overflow al mostrar el banner de coleccionable (fallo en `should_win_level_12_with_single_shot`) |

**Verificación local:**

- **BackEnd-ArrowMaze:** 175/175 tests pasando (`npm test`).
- **Arrow-Maze-Escape-Puzzle:** 122/122 tests pasando (`flutter test`).
- Hash SHA-256 de `progress-get-response.json` coincidente entre ambos repos locales.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Pendiente de commit y push en el frontend (`develop`) para que el CI remoto deje de comparar contra el fixture antiguo en GitHub.

**Lecciones aprendidas o limitaciones identificadas.**

- Cuando el contrato REST evoluciona (p. ej. campo `collectibles` en `GET /progress`), hay que actualizar el fixture en **ambos** repos antes de merge; el script `check-contract-fixtures-sync.sh` compara hashes contra la rama remota del otro repo.
- Los tests de contrato deben seguir el tipo de retorno real del cliente HTTP (`RemotePlayerProgress`), no el modelo anterior.
- Añadir UI condicional en pantallas de resultado (banner de coleccionable) puede romper tests E2E por overflow; conviene diseñar layouts scrollables desde el inicio.

## Consulta #48 — Generación de ejecutables de Android e iOS para la entrega académica

**Tarea o problema abordado.**

El enunciado del proyecto exige entregar un ejecutable de la app para Android y/o iOS. Se solicitó generar ambos, evaluando previamente el estado real del entorno de desarrollo antes de proponer una ruta de trabajo.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal con acceso de lectura/escritura al repositorio y ejecución de comandos de sistema (instalación de herramientas, compilación, gestión del Simulador de iOS).

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Uno de los requisitos es generar un ejecutable para Android o iOS. Si quisiera hacer ambos, ¿qué debería hacer y cómo?
>
> [Turnos posteriores, resumidos] ¿Podrías hacer tú lo necesario para correr en iOS? / Sí, prepara ambos (Android e iOS) para que el profesor pueda probarlos.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Un diagnóstico inicial (`flutter doctor -v`) reveló que ni el SDK de Android ni Xcode completo estaban instalados en la máquina. Se resolvió de punta a punta:

- **Android:** instalación de Java 17 y Android SDK (cmdline-tools) vía Homebrew; generación de un keystore de release propio (`keytool`); configuración de firma real en `android/app/build.gradle.kts` (carga `android/key.properties`, con *fallback* a las llaves de debug si el archivo no existe, para no romper CI ni otras máquinas); compilación de `flutter build apk --release`.
- **iOS:** activación de Xcode (`xcode-select`) vía diálogo nativo de administrador de macOS (sin exponer la contraseña del usuario); cuenta Apple ID personal gratuita agregada en Xcode; firma automática (`CODE_SIGN_STYLE = Automatic`, `DEVELOPMENT_TEAM`) configurada en `ios/Runner.xcodeproj/project.pbxproj`; instalación y ejecución verificada tanto en el Simulador de iOS como en un iPhone físico del usuario (confiando manualmente el certificado de desarrollador en Ajustes del dispositivo, paso que solo el usuario puede completar).

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó instalando y ejecutando ambos artefactos (APK en Android, build en Simulador e iPhone físico).

**Lecciones aprendidas o limitaciones identificadas.**

- Sin cuenta de Apple Developer Program de pago, la firma personal gratuita permite correr la app en un dispositivo propio (validez ~7 días, renovable reconectando y recompilando), pero no genera un `.ipa` distribuible a terceros sin herramientas adicionales (AltStore/Sideloadly) o sin que cada persona lo firme con su propia cuenta.
- Antes de planificar un cambio de build/despliegue conviene diagnosticar el entorno real (`flutter doctor -v`) en vez de asumir que las herramientas ya están instaladas: eso determina qué parte del pedido se resuelve con cambios de archivo y cuál requiere instalación interactiva que solo el usuario puede autorizar (contraseñas de administrador, inicio de sesión con Apple ID).

## Consulta #49 — Backend en la nube (Render) para pruebas independientes del presentador

**Tarea o problema abordado.**

Los ejecutables generados apuntaban por defecto a `localhost`/la red local del presentador, lo cual solo funciona durante una demostración en vivo. Se solicitó que el profesor pudiera probar la app tanto en la defensa como después, desde su casa, sin depender de la red ni de la presencia del estudiante.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> ¿Cómo podría hacer para que el profesor pueda probar esta app, tanto en la presentación final como luego que hayamos defendido, cuando esté corrigiendo el proyecto en su casa?
>
> [Tras aclarar que Supabase no encaja con el backend Express/SQLite existente] Puedes hostearlo en la web, en Render.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se explicó por qué Supabase no era compatible sin reescribir el backend (es Postgres + Auth + Edge Functions, no un host genérico de Node/Express), y se desplegó el backend existente sin cambios de arquitectura en Render.com (plan gratuito). Los ejecutables de Android e iOS se recompilaron con `--dart-define=API_BASE_URL=https://backend-arrowmaze.onrender.com`, quedando autocontenidos: no requieren que el estudiante esté presente ni en la misma red.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- El usuario creó la cuenta y el servicio en Render (paso que requiere credenciales propias, fuera del alcance de lo que la IA puede hacer) y proveyó la URL pública resultante.

**Lecciones aprendidas o limitaciones identificadas.**

- El plan gratuito de Render no incluye disco persistente por defecto: los datos (usuarios, progreso) se reinician con cada redeploy/reinicio del servicio, mientras que el catálogo de niveles se resiembra solo desde los archivos del repositorio. Esto es deseable para dejar el entorno "limpio" antes de una defensa.
- El plan gratuito también "duerme" el servicio tras inactividad, por lo que el primer inicio de sesión tras un rato sin uso puede tardar unos segundos adicionales (cold start) — se documentó esta expectativa en las instrucciones para el usuario final.

## Consulta #50 — Bug: el APK de Android no lograba conectarse al backend

**Tarea o problema abordado.**

Tras instalar el primer APK de release en un teléfono Android físico, el registro/login fallaba con "Couldn't reach the server" pese a que el backend en Render respondía correctamente desde otras herramientas.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal, incluyendo inspección del `.apk` generado con `aapt2`.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> El APK en Android no se conecta, parece haber problemas con el servidor, valida eso por favor.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se confirmó primero que el backend respondía sin problemas (`curl` exitoso contra `/health` y `/levels`), descartando un problema de servidor. La causa real: `android/app/src/main/AndroidManifest.xml` no declaraba `<uses-permission android:name="android.permission.INTERNET"/>` — sin ese permiso, ninguna app Android puede hacer peticiones de red, sin importar el servidor de destino. Se agregó el permiso y se verificó con `aapt2 dump permissions` que quedó presente en el APK reconstruido.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó reconstruyendo el APK y confirmando el permiso en el paquete final.

**Lecciones aprendidas o limitaciones identificadas.**

- Un bloqueo de conectividad no siempre está del lado del servidor: verificar el backend de forma independiente (`curl`) antes de investigar el cliente evita perder tiempo revisando el lado equivocado.
- El permiso `INTERNET` es fácil de dar por sentado porque muchos templates de Flutter lo incluyen por defecto; conviene confirmarlo explícitamente en cualquier proyecto que no se haya probado antes en un dispositivo Android real.

## Consulta #51 — Bug: la música de fondo se detenía al tocar cualquier botón

**Tarea o problema abordado.**

Al probar el APK en Android, se reportó que la música de fondo sonaba al abrir la app pero se detenía apenas se tocaba el botón "Play" (o cualquier otro).

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal con lectura del código fuente del paquete `audioplayers`.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Tengo la siguiente situación probando en Android: la música está sonando al correr la app, pero cuando le doy play, deja de sonar.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Causa: el paquete `audioplayers` solicita foco de audio **exclusivo** (`AndroidAudioFocus.gain`) por defecto en cada instancia de `AudioPlayer` en Android. Como el clic de botón usa un reproductor distinto al de la música, Android le retiraba el foco (y por tanto la reproducción) al reproductor de música apenas sonaba cualquier efecto. Se configuró `AndroidAudioFocus.none` en todos los reproductores (música y pool de efectos) en `lib/infrastructure/audio/app_audio_service.dart`, para que convivan sin interrumpirse entre sí.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con `flutter analyze`/`flutter test` y reinstalando el APK reconstruido.

**Lecciones aprendidas o limitaciones identificadas.**

- El comportamiento por defecto de foco de audio en Android puede interrumpir sonidos de la propia app entre sí, no solo frente a otras apps; conviene revisar explícitamente esta configuración en cualquier librería de audio usada en un juego con música + efectos simultáneos.

## Consulta #52 — Botón de reinicio de nivel en la pantalla de juego

**Tarea o problema abordado.**

Se solicitó agregar un botón en la pantalla de juego que permita reiniciar el nivel actual, respetando la paleta de colores existente y con una presentación visualmente atractiva.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal con acceso de lectura/escritura al repositorio.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Quisiera le agregaras un nuevo botón a la ventana donde se ve el tablero de juego, el cual permita reiniciar el nivel, que respete la paleta de colores usada y sea atractivo.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se agregó `BoardRestartButton` (`lib/presentation/game/widgets/board_view.dart`), con el mismo estilo que el botón existente de cuadrícula (fondo semitransparente redondeado) pero con ícono `replay` en el acento rosa de la paleta (`AppColors.arrowBlocked`), junto al contador de movimientos. Al tocarlo, se muestra un diálogo de confirmación (para evitar perder progreso por accidente) antes de invocar `GameController.retry()`, ya existente.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con `flutter test` (prueba nueva que confirma que cancelar no altera el progreso y confirmar sí lo reinicia).

**Lecciones aprendidas o limitaciones identificadas.**

- Una acción que reinicia progreso de partida se beneficia de una confirmación explícita, incluso sin que el usuario la pidiera expresamente: previene una pérdida de progreso accidental por un toque desprevenido.

## Consulta #53 — Tutorial interactivo del nivel 1 para adultos mayores y niños

**Tarea o problema abordado.**

Se consultó cómo agregar un tutorial de cómo jugar, pensado explícitamente para adultos mayores y personas muy jóvenes — audiencias donde el texto instructivo estático suele ignorarse o no retenerse.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, en modo de planificación (exploración del código existente y una pregunta de alcance al usuario) seguido de implementación.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Si quisiéramos agregar un tutorial de cómo se juega, para personas mayores o muy pequeñas, ¿cómo podríamos hacerlo? Se me ocurren imágenes con texto, pero ¿qué opinas?
>
> [Tras presentar tres alcances posibles] Guía interactiva en el primer nivel real.

**Resultado obtenido (fragmento de código, diseño, explicación).**

En vez de diapositivas estáticas, se implementó `GameTutorialOverlay` (`lib/presentation/game/widgets/game_tutorial_overlay.dart`): la primera vez que alguien entra al nivel 1, se resalta la primera flecha con un anillo pulsante y un mensaje breve ("Toca esta flecha para dispararla") hasta que la persona la toca — aprendizaje por acción, no por lectura. Al tocar cualquier flecha, se muestra un segundo mensaje sobre el objetivo del nivel, que se desvanece solo. Siempre es posible omitirlo, y una vez visto (u omitido) no vuelve a aparecer — estado persistido vía un nuevo `IAppSettings.hasSeenTutorial`. Se agregó además una entrada "Ver tutorial de nuevo" en Ajustes.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con `flutter test` (pruebas nuevas cubriendo aparición, avance al tocar, omisión y persistencia del estado).

**Lecciones aprendidas o limitaciones identificadas.**

- Para audiencias con dificultad de lectura, un tutorial que avanza según la acción real del usuario (no un botón "Siguiente") es más confiable que texto pasivo, porque no se puede saltar sin haber realizado al menos la acción principal.
- `pumpAndSettle()` no es compatible con animaciones en bucle infinito (`AnimationController.repeat()`); las pruebas de widget para este tipo de UI deben usar `pump()` con duraciones fijas en su lugar.

## Consulta #54 — Ajuste de "Ver tutorial de nuevo" para navegar directo al nivel 1

**Tarea o problema abordado.**

El botón "Ver tutorial de nuevo" (Consulta #53) solo reiniciaba una bandera interna; el usuario debía luego buscar el nivel 1 manualmente en el catálogo para verlo. Se solicitó que el tutorial pudiera verse tantas veces como el usuario quisiera, de forma más directa.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> Necesito activar el botón de ver tutorial, ya que solo se ve una vez y ya, debe poder verse tantas veces como el usuario quiera.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se modificó `SettingsScreen` para que, al tocar "Ver tutorial de nuevo", además de reactivar la bandera, resuelva el nivel 1 desde el repositorio de niveles y navegue directamente a la pantalla de juego (`Navigator.pushNamed('/game', ...)`), mostrando el tutorial de inmediato sin pasos intermedios.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con una prueba de widget que confirma el reseteo de la bandera y la navegación al nivel correcto.

**Lecciones aprendidas o limitaciones identificadas.**

- Ante una petición ambigua ("debe poder verse tantas veces como quiera"), preguntar explícitamente qué comportamiento exacto se espera (navegación directa vs. tutorial disponible desde cualquier nivel) evitó implementar la interpretación equivocada.

## Consulta #55 — Bug crítico: un nivel con dato inesperado tumbaba todo el catálogo

**Tarea o problema abordado.**

Con el backend ya desplegado en Render, la app dejó de poder cargar el catálogo de niveles ("Could not load the level catalog") para un usuario específico, incluso después de refrescar.

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal, incluyendo inspección directa del almacenamiento local del Simulador de iOS (`SharedPreferences` en disco) y un script Dart de un solo uso para reproducir el mapeo real de niveles contra datos capturados del dispositivo.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> El APK en Android no se conecta / El backend en Render responde bien, pero la app sigue sin poder cargar el catálogo — valida eso por favor.

**Resultado obtenido (fragmento de código, diseño, explicación).**

Se determinó que la rama `main` del backend (la que Render despliega) tiene 8 niveles que no existen en `develop`, agregados directamente por un integrante del equipo. Inspeccionando el caché local (`SharedPreferences`) del dispositivo se encontró que en algún momento el backend sirvió `level-30` con `difficulty: "LEGENDARY"` — un valor que el `enum` de dificultad del cliente no reconoce — y ese valor quedó cacheado localmente. El bug real: `CachedLevelRepository` (y `RemoteLevelRepository`) abortaban la carga de **todo** el catálogo si un solo nivel fallaba al traducirse, sin poder recuperarse aunque el servidor ya estuviera corregido. Se modificó `CachedLevelRepository._mapAndSort` para omitir (con un log) el nivel que falle, en vez de descartar los demás niveles válidos — mismo criterio que ya aplicaba el backend ("saltar niveles no resolubles en vez de tumbar el servidor").

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con una prueba nueva que reproduce exactamente el caso (un nivel con `difficulty: "LEGENDARY"` junto a uno válido) y confirma que el nivel válido sigue cargando.

**Lecciones aprendidas o limitaciones identificadas.**

- Un solo registro remoto inesperado no debería poder inutilizar toda una funcionalidad para todos los usuarios; aplicar el mismo principio de resiliencia en cliente y servidor (omitir en vez de abortar) evita que un dato aislado bloquee a alguien de forma persistente, incluso después de corregido el origen del problema.
- Inspeccionar directamente el almacenamiento local persistido en el dispositivo (en vez de solo asumir hipótesis sobre la causa) fue decisivo para encontrar la causa real en minutos en lugar de conjeturar indefinidamente.
- Cuando dos ramas de un mismo repositorio divergen (`main` con niveles que `develop` no tiene), vale la pena señalarlo al equipo como una alerta de gobernanza, aunque no sea el objetivo directo de la tarea.

## Consulta #56 — Bug: la música de fondo seguía sonando al salir de la app

**Tarea o problema abordado.**

Se reportó que, en Android, la música del juego se mantenía sonando incluso después de salir de la app (segundo plano).

**Herramienta de IA utilizada.**

- Claude Code (Anthropic), modelo Sonnet 5, sesión interactiva de terminal.

**Prompt o instrucción proporcionada (transcripción literal o paráfrasis fiel).**

> En los Androids, la música del juego se mantiene aun cuando sales de la app, ¿puedes corregirlo?

**Resultado obtenido (fragmento de código, diseño, explicación).**

La causa: la app nunca escuchaba los cambios de ciclo de vida (`AppLifecycleState`) — no existía ningún `WidgetsBindingObserver`, así que nada pausaba el reproductor al pasar a segundo plano. Se agregó el observer en `_ArrowMazeAppState` (`lib/main.dart`), que pausa la música al pasar a `paused`/`hidden`/`detached` y la retoma al volver a `resumed`, respetando el silencio configurado.

**Modificaciones realizadas por el equipo al resultado de la IA.**

- Ninguna; se verificó con dos pruebas nuevas que simulan transiciones de ciclo de vida reales sobre la app completa (`ArrowMazeApp`) con un servicio de audio espía, confirmando pausa/reanudación y que no se reactiva si está silenciada.

**Lecciones aprendidas o limitaciones identificadas.**

- Cualquier reproducción de audio en bucle debe atarse explícitamente al ciclo de vida de la aplicación; sin un `WidgetsBindingObserver`, el estado de "en primer plano" nunca se propaga a servicios que gestionan recursos del sistema como el audio.

---

## Evaluación crítica

**Porcentaje aproximado del código que contó con asistencia de IA.**

- La gran mayoría del proyecto: prácticamente el 100% de la capa de dominio, casos de uso, adaptadores de interfaz, infraestructura (HTTP, `SharedPreferences`, audio) y presentación (pantallas y controladores) se generó con asistencia de IA a partir de prompts detallados, validado en cada consulta con `flutter analyze`/`flutter test` y, en los cambios de UI, con verificación visual o pruebas de widget.
- Estimado global: 90-95% del código final tiene asistencia de IA en su primera versión; el resto corresponde a ajustes manuales puntuales y a las decisiones de alcance/diseño que el equipo tomó explícitamente antes de cada implementación (frecuentes en las consultas que usan modo de planificación con aprobación previa).

**Casos donde la IA produjo resultados incorrectos o subóptimos y cómo se detectaron y corrigieron.**

- Bugs de plataforma detectados solo con verificación en dispositivo real, no con tests: el APK de Android que no conectaba con el backend (Consulta #50) se diagnosticó inspeccionando el `.apk` generado con `aapt2`; el mapeo incorrecto de niveles se reprodujo con datos capturados directamente del almacenamiento local del Simulador de iOS, no con una suposición sobre el comportamiento esperado.
- Errores de ciclo de vida de Flutter (música de fondo que no se pausaba en background, tanto en la versión inicial como en una regresión posterior) — ambos casos solo se manifestaban en el comportamiento real de la app, no en un test unitario aislado, y requirieron pruebas de widget que simulan transiciones de `AppLifecycleState` para confirmarlos y luego verificar el fix.
- Se descartó explícitamente el uso de Pact para pruebas de contrato tras investigar que no tiene un SDK de consumidor oficial ni bien mantenido para Dart/Flutter, evitando adoptar una herramienta recomendada por el enunciado que en la práctica no encajaba con el stack — se optó por un mecanismo de sincronización de fixtures compartido con el backend en su lugar.
- Ningún caso detectado de error conceptual de arquitectura o de patrón de diseño mal aplicado a nivel de diseño; los errores encontrados fueron de comportamiento en tiempo de ejecución (ciclo de vida, plataforma, red) que solo la verificación end-to-end pudo exponer.

**Reflexión del equipo sobre el impacto de la IA en la productividad y calidad del código.**

- El impacto fue muy positivo en velocidad de iteración: features completas (sincronización offline-first, coleccionables, sistema de audio contextual, tutorial interactivo) se implementaron con pruebas de principio a fin en sesiones individuales, muchas veces coordinando cambios simétricos en ambos repositorios (frontend y backend) dentro de la misma sesión.
- La lección más repetida a lo largo del proyecto es que los bugs más difíciles de encontrar con solo "leer el código" fueron los de comportamiento real en el dispositivo (ciclo de vida de la app, artefactos de compilación, almacenamiento local) — en esos casos, reproducir el problema en vivo antes de proponer un fix, y volver a verificar en vivo después, fue más confiable que confiar en el razonamiento de la IA sobre el código estático.
- Delegar exploraciones de solo lectura a subagentes especializados (por ejemplo, auditar `lib/` en busca de literales de UI fuera de `app_strings.dart`) permitió mantener las sesiones principales enfocadas en implementación sin perder cobertura de la exploración.
- La disciplina de pedir aprobación explícita antes de comitear o pushear a ramas compartidas, adoptada de forma creciente en las consultas más recientes, evitó que cambios exploratorios llegaran a `main`/`develop` sin revisión.

