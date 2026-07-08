# Arrow Maze — Estado del proyecto (post Sprint 1, frontend)

> Lee esto antes de tocar código. Resume qué se hizo, qué falta, y por qué se tomó cada decisión, para que cualquiera del equipo pueda seguir sin tener que re-preguntar el contexto.

**Última actualización:** 08-jul-2026 · **Entrega final del proyecto:** 23-jul-2026 (prorrogada; el enunciado original decía 03-jul-2026)

## Contexto rápido (por qué existió una "Fase de fusión")

Antes de Sprint 1, dos compañeros habían construido **el mismo dominio dos veces, sin coordinarse**, en dos ramas remotas distintas:
- `Develop`: dominio rico en **inglés**, organizado por bounded context (`board`, `game`, `level`, `player`, `progress`), pero su `pubspec.yaml` **no dependía de Flutter** — no era una app ejecutable.
- `Integracion`: dominio más simple en **español**, pero con `pubspec.yaml`/`main.dart` de Flutter reales — la única de las dos que sí arrancaba como app.

Ninguna de las dos estaba fusionada a `main` (que estaba casi vacío). Sprint 1 fusionó ambas en `feature/merge-domain-and-shell`, tomando el dominio de `Develop` como base y el "shell" de Flutter de `Integracion`.

## ✅ Qué se hizo en Sprint 1 (rama `feature/merge-domain-and-shell`, sobre `Develop`)

Commits, de más antiguo a más reciente:

| Commit | Qué hace |
|---|---|
| `e9d9073` | Trae `pubspec.yaml`/`main.dart` de `Integracion` y los reconcilia con el dominio de `Develop` (agrega dependencia de Flutter, mantiene `meta`/`test`) |
| `78e13cc` | Porta **pausa/reanudación** y **puntaje**: `GameStatus.paused`, `Game.pause()/resume()`, `Game.score`, `Game.completionPercentage()` |
| `f5136f9` | Porta **reinicio de flecha**: `Arrow.reset()` |
| `4fe5787` | Porta **resultado "sin flecha"** (`MoveResultType.noArrowAtCell`, `ArrowMovementEngine.attemptMoveAt()`) y **eventos de dominio del tablero** (`Board.domainEvents`/`withDomainEvent()`/`pullDomainEvents()` — antes código muerto, ahora `ArrowBlockedEvent`/`ArrowExtractedEvent` se emiten de verdad) |
| `1322dd3` | Porta **presets de generación por dificultad**: `LevelGenerationConfig.fromDifficulty()` |
| `3f64ec7` | Primeras pruebas AAA para los 6 comportamientos portados (`test/domain/board/arrow_test.dart`, `board_events_test.dart`, `test/domain/game/game_test.dart`) |
| `71f0d0b` | CI: `.github/workflows/ci.yml` (`pub get` + `analyze` + `test` en cada PR/push a `main`) |
| `d7066b8`, `9fb3304` | `AI_USAGE.md` unificado (se renombró `IA_USAGE.md` → `AI_USAGE.md`) con la entrada de la fusión |
| `6ca374a`, `f30df4e` | `README.md` completo (12 secciones obligatorias) + diagrama de capas Clean Architecture (corregido tras un error de sintaxis Mermaid) |
| `a26d346` | Corrige los **5 problemas reales** que encontró `flutter analyze` corriendo de verdad (2 imports sin usar, un `library domain;` innecesario, 2 casos de documentación faltante) |
| `ffbe67a` | **Genera el scaffold de plataformas** (`android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`) — el proyecto fusionado nunca había corrido `flutter create`, así que `flutter run` no tenía dónde ejecutar |
| `3f03d4b` | Documenta en `AI_USAGE.md` la verificación real con Flutter instalado |

**Todo esto se verificó con Flutter 3.44.5 real instalado (no solo revisado a mano):** `flutter pub get` (60 dependencias resueltas), `flutter analyze` (**No issues found!**), `flutter test` (**12/12 tests pasan**), `flutter build web` (compila y genera el bundle).

⚠️ **Importante — qué NO prueba esta verificación**: `flutter build web` solo confirma que el *cascarón* de Flutter (scaffold de plataformas + `main.dart` placeholder) compila y sirve. La pantalla actual es literalmente un `Text('Arrow-Maze Escape Puzzle')` centrado — no tiene tablero, ni flechas, ni ninguna conexión con el dominio. La prueba real de que la lógica del juego quedó bien fusionada es **`flutter test` (los 12 tests)**, que sí ejercitan `Board`, `Game`, `Arrow`, `ArrowMovementEngine`, etc.

## 🔲 Qué falta para cerrar Sprint 1

1. **Abrir/revisar/fusionar el PR**: `feature/merge-domain-and-shell` → `main`. Link: https://github.com/Mianjoy/Arrow-Maze-Escape-Puzzle/pull/new/feature/merge-domain-and-shell
2. **Confirmar CI en verde** en la pestaña Actions del PR.
3. **Borrar `Develop` e `Integracion`** en GitHub una vez fusionado (ya cumplieron su propósito).
4. **Revisar la rama local `Jean_Front`** (`git log Jean_Front ^main`) — si no tiene nada que no esté ya en la fusión, se puede borrar.
5. **Protección de rama en `main`** (status check obligatorio + 1 aprobación) — necesita permisos de admin del repo en GitHub Settings → Branches.

## 🗺️ Qué sigue después (Sprint 2, 12–17 jul)

Con el dominio unificado y el scaffold de plataformas listo, Sprint 2 construye la app real:

- **`lib/interface_adapters`** (carpeta nueva, aún no existe): traduce el contrato `StructuredLevelJsonDto` del backend (ver `docs/contract/level.contract.ts` en el repo backend) a las entidades de dominio (`Board`, `Arrow`, `Level`) — el backend ya tiene su lado listo y probado (`LevelJsonMapper`).
- **Capa de aplicación**: casos de uso de mover/rotar flecha (patrones **State** + **Factory**), cargar nivel, guardar progreso.
- **Primeras pantallas reales**, reemplazando el placeholder de `main.dart`: inicio, selección de nivel, juego, victoria, derrota.
- **Persistencia local** del progreso del jugador.
- Conectar con los endpoints del backend (`/auth`, `/progress`, `/leaderboard`, `/levels`) cuando existan.

**Sprint 3** (18–21 jul): integración app-backend real, los 15 niveles diseñados a mano, audio (con mute), i18n (español + inglés mínimo), cobertura de tests widget/integración, diagrama de clases final.
**Sprint 4** (22–23 jul): build final, documentación pulida, ensayo de defensa individual.

## Cómo arrancar a trabajar en este repo

```bash
git checkout feature/merge-domain-and-shell   # o main, una vez fusionado
flutter pub get
flutter analyze
flutter test
flutter run -d chrome   # o un emulador/dispositivo conectado
```

Si `flutter` no está instalado: `brew install --cask flutter` (macOS) y luego `flutter doctor` para confirmar qué plataformas están disponibles en tu máquina (Chrome/Web no necesita Android Studio ni Xcode).

## Convenciones que hay que seguir (acordadas para todo el proyecto)

- **Comentarios en español** en cada función/método nuevo, no solo en las complejas — todo el código portado en Sprint 1 sigue esta convención, úsala de referencia.
- **`AI_USAGE.md` se actualiza en el momento**, no se deja acumulado.
- **Conventional Commits** — ya verificado que todos los commits de Sprint 1 lo cumplen.
- El dominio se mantiene **en inglés** (fue la decisión explícita al fusionar `Develop`+`Integracion`); no volver a introducir nombres en español en el dominio.

## Decisiones y hallazgos importantes de Sprint 1 (para no repetir la discusión)

- **Por qué `Develop` y no `Integracion` como base**: `Develop` tenía el dominio más completo (eventos, cálculo de ruta óptima, sistema de estrellas) y en inglés, alineado con el resto de convenciones del proyecto. `Integracion` solo aportó el "shell" de Flutter real (`pubspec.yaml`/`main.dart`), que sí se rescató.
- **6 comportamientos se portaron manualmente** de `Integracion` a `Develop` porque existían solo en la versión en español (ver tabla de commits arriba) — si algo del juego no se comporta como esperabas (pausa, puntaje, reinicio), revisa esa tabla primero.
- **El scaffold de plataformas no existía** hasta Sprint 1 — si ves código Android/iOS/web "de la nada" en el historial, es autogenerado por `flutter create .`, no fue escrito a mano.
- **`docs/architecture/clean-architecture.mmd` se rompió una vez** por un bug de sintaxis Mermaid (un bloque de comentarios `%%` al inicio se fusionaba con `flowchart TB`) — ya está corregido y verificado con `@mermaid-js/mermaid-cli`; si edites ese archivo, no vuelvas a poner comentarios antes de la declaración del diagrama.
