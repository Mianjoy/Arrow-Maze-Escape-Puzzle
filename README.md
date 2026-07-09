# Arrow Maze Escape Puzzle

![CI](https://github.com/Mianjoy/Arrow-Maze-Escape-Puzzle/actions/workflows/ci.yml/badge.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.24-blue)
![Dart](https://img.shields.io/badge/Dart-3.5-blue)
![Tests](https://img.shields.io/badge/tests-unit%20%2B%20widget%20%2B%20e2e-brightgreen)
![License](https://img.shields.io/badge/license-Academic-lightgrey)

## Description

*Arrow Maze Escape Puzzle* is a mobile puzzle game where the player extracts all the
arrows from a board by firing them in the direction they point, without colliding
with other arrows. Built with **Flutter** following **Clean Architecture** and
**SOLID** principles.

The app is fully playable end to end: home, level select (with lock/completion/star
indicators), the game board, victory/defeat screens, local audio with mute, and two
languages (English/Spanish). It authenticates against the
[BackEnd-ArrowMaze](https://github.com/Georopeza/BackEnd-ArrowMaze) API, downloads and
caches the 15-level catalog for offline play, and keeps player progress in sync with
the server in both directions — push on victory (with a retry queue for offline wins)
and pull-and-merge on login, so progress follows the player across devices.

## Demo / Screenshots

_TBD — pending a recorded GIF/screenshots of the running app for this section._

## Architecture

Four Clean Architecture layers, dependencies pointing inward (outer layers depend on
inner ones, never the reverse):

```mermaid
flowchart TB
    subgraph L4["Presentation"]
        direction TB
        UI["Screens + Controllers (ChangeNotifier): home, level select,
        game, victory, defeat, auth, leaderboard, settings"]
    end
    subgraph L3["Infrastructure & Interface Adapters"]
        direction TB
        Adapters["lib/interface_adapters: LevelDtoMapper, PlayerProgressJsonMapper"]
        Infra["lib/infrastructure: HTTP clients, SharedPreferences repositories, audio"]
    end
    subgraph L2["Application"]
        direction TB
        UseCases["Use cases: LoadLevels, StartGame, FireArrow, RecordVictory,
        SyncPendingProgress, PullRemoteProgress, Login/Register/Logout"]
    end
    subgraph L1["Domain"]
        direction TB
        Entities["Board, Game, Level, Player, PlayerProgress (bounded contexts)"]
    end

    L4 --> L3 --> L2 --> L1
```

Source: [`docs/architecture/clean-architecture.mmd`](docs/architecture/clean-architecture.mmd)

| Layer | Responsibility | Status |
|---|---|---|
| **Domain** | Entities, aggregates, value objects, domain services, events, repository ports | ✅ Implemented |
| **Application** | Use cases and orchestration | ✅ Implemented |
| **Infrastructure / Interface Adapters** | Local persistence, backend API clients, DTO↔domain mapping | ✅ Implemented |
| **Presentation** | Flutter screens and controllers | ✅ Implemented |

### Domain layer

```
lib/domain/
├── shared/           # Cross-cutting value objects, enums and exceptions
├── player/           # Player and profile
├── board/            # Board, Cell, Arrow (state entities), domain events
├── level/             # Level (aggregate), JSON loading, star rating, generation presets
├── game/              # Game (active session aggregate): moves, pause/resume, score
├── progress/          # Player progress per level, remote merge logic
└── repositories/      # Persistence contracts (interfaces)
```

### Aggregate roots

| Aggregate | Responsibility |
|---|---|
| **Level** | Level definition from JSON, initial board, optimal path |
| **Game** | Coordinates moves, pause/resume, score, win/loss and star rating during a session |
| **PlayerProfile** | Player profile and statistics |
| **PlayerProgress** | Progress and best stars per level; merges remote (server) progress with local |

### Level contract with the backend

Levels are loaded from the [BackEnd-ArrowMaze](https://github.com/Georopeza/BackEnd-ArrowMaze)
API using the shared `StructuredLevelJsonDto` contract (source of truth lives in the
backend repo, at `docs/contract/level.contract.ts`, mirrored in `lib/contract/`). The
domain layer stays unaware of this wire format: `lib/interface_adapters/level_dto_mapper.dart`
translates it into `Board`/`Arrow`/`Level` entities, computing the optimal path and
rejecting unsolvable levels before they ever reach the UI.

### Offline-first level catalog and progress sync

- `CachedLevelRepository` (`lib/infrastructure/level/`) fetches `GET /levels` and writes
  the raw catalog to `SharedPreferences`; if the network fails, it serves the last
  cached copy instead of a bundled fallback, so the 15-level catalog stays playable
  offline.
- `RecordVictoryUseCase` always saves progress locally first; if the push to the server
  fails, the win is enqueued (`PendingSyncEntry`) instead of lost, and
  `SyncPendingProgressUseCase` retries it the next time the level list loads.
- `PullRemoteProgressUseCase` downloads the player's server-side progress on every
  level-list load and merges it into local progress (`PlayerProgress.mergeRemoteLevel`,
  best score/moves/time per level, never downgrading completion status).

## Design Patterns

| Pattern | Category | Where |
|---|---|---|
| **Aggregate Root** | — (DDD) | `Level`, `Game`, `PlayerProfile`, `PlayerProgress` |
| **Value Object** | — (DDD) | `Position`, `Direction`, `StarRating`, `LevelBoardDefinition`, etc. |
| **Factory Method** | Creational | `LevelFactory`, `BoardFactory`, `CellFactory` |
| **Decorator** | Structural | `CachedLevelRepository` wraps the remote source with a write-through local cache behind the same `ILevelRepository` port |
| **Adapter** | Structural | `LevelDtoMapper` (wire format ↔ domain), `PlayerProgressJsonMapper` |
| **Repository (DIP)** | Structural | Interfaces in `lib/domain/repositories/` and `lib/application/ports/` |
| **Domain Event** | Behavioral | `GameWonEvent`, `ArrowExtractedEvent`, `ArrowBlockedEvent`, raised via `Board.pullDomainEvents()` |
| **Domain Service** | Behavioral | `ShortestPathCalculator`, `StarRatingCalculator`, `ArrowMovementEngine`, `CollisionValidator` |

## SOLID Principles

- **SRP** — `Board` only manages board state; `Game` coordinates session rules;
  `LevelFactory` only builds levels from JSON; `RecordVictoryUseCase` only persists a
  victory and queues a retry, it doesn't decide how the UI reports the result.
- **OCP** — new `Cell` subtypes or domain events can be added without changing
  `Board`/`Game`; `LevelGenerationConfig.fromDifficulty()` adds new difficulty presets
  without touching `LevelFactory`.
- **LSP** — every `Cell` subtype is substitutable wherever `Cell` is expected.
- **ISP** — repository ports (`IGameRepository`, `IPlayerProfileRepository`,
  `IPlayerProgressRepository`, `IPendingSyncRepository`) are split by aggregate instead
  of one large repository interface.
- **DIP** — `ArrowMovementEngine` depends on `ICollisionValidator`, not on a concrete
  validator. A clearer example, `CachedLevelRepository` and `RecordVictoryUseCase` both
  depend only on `ILevelRepository`/`IPendingSyncRepository` ports:
  ```dart
  class CachedLevelRepository implements ILevelRepository {
    CachedLevelRepository({
      required LevelApiClient apiClient,
      required SharedPreferences prefs,
      LevelDtoMapper? mapper,
    });
    // ...
  }
  ```
  The composition root (`AppContainer` in `lib/main.dart`) is the only place that wires
  concrete implementations — swapping the cache strategy or the HTTP client means
  changing that one file, not any use case or screen.

## AOP

Cross-cutting concerns are kept out of business logic via composition, without any use
case importing a logger or catching network errors on its own:

1. **Domain events** — `Board.withDomainEvent()` / `Board.pullDomainEvents()` let
   `ArrowMovementEngine` raise `ArrowBlockedEvent`/`ArrowExtractedEvent` on every move,
   decoupling notification from the movement logic itself.
2. **Offline resilience as a decorator** — `CachedLevelRepository` transparently adds
   caching/fallback behavior around the remote level source; no use case or screen
   needs to know whether data came from the network or the cache.
3. **Best-effort sync retry** — `SyncPendingProgressUseCase` and `PullRemoteProgressUseCase`
   run as a side effect of `LevelSelectController.load()` and swallow their own
   failures, so a flaky connection never surfaces as a crash or a blocked screen — the
   UI just shows an "offline" notice instead of an error.

## Getting Started

```bash
flutter pub get
flutter run          # or: flutter run -d chrome
```

By default the app talks to a backend at `http://localhost:3000`; override with
`--dart-define=API_BASE_URL=<url>` (e.g. `http://10.0.2.2:3000` on an Android
emulator). See [BackEnd-ArrowMaze](https://github.com/Georopeza/BackEnd-ArrowMaze) for
how to run the API locally.

## Running Tests

```bash
flutter analyze
flutter test
```

The suite covers all four layers: domain unit tests (`test/domain/`), use-case unit
tests with fakes/mocks (`test/application/`), infrastructure tests with a mocked HTTP
client (`test/infrastructure/`), widget tests for screens (`test/presentation/`), and
end-to-end tests that simulate a full remote catalog and play through victory/defeat
(`test/e2e/`). CI (`.github/workflows/ci.yml`) runs `pub get`, `analyze` and `test` on
every PR/push to `main`.

## AI Usage Documentation

See [AI_USAGE.md](AI_USAGE.md) for the full log of AI-assisted tasks (tool, prompt,
result, team adjustments, lessons learned).

## Contributing

1. Create a branch off `main` (e.g. `feature/<short-description>`).
2. Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit
   messages (enforced via `commitlint`).
3. Run `flutter analyze && flutter test` before opening a PR.
4. Open a PR against `main`; CI must pass and at least one teammate must approve
   before merging.

## License

Academic project for Desarrollo de Software (UCAB). No license has been chosen yet;
all rights reserved by the team until one is added.
