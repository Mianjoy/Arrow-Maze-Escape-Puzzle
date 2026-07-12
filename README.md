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
indicators), the game board, victory/defeat screens, a collectibles gallery unlocked by
milestone-level performance, contextual sound effects (button clicks, arrow extraction,
blocked moves, level cleared, time/moves exhausted) plus background music and a
per-level countdown timer, all behind a mutable `IAudioService` port, and two languages
(English/Spanish). It authenticates against the
[BackEnd-ArrowMaze](https://github.com/Georopeza/BackEnd-ArrowMaze) API, downloads and
caches the 15-level catalog for offline play, and keeps player progress — including
unlocked collectibles — in sync with the server in both directions: push on victory
(with a retry queue for offline wins) and pull-and-merge on login, so progress follows
the player across devices.

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
        game, victory, defeat, auth, leaderboard, settings, collectibles gallery"]
        AudioScope["AudioScope (provides IAudioService to the widget tree)"]
    end
    subgraph L3["Infrastructure & Interface Adapters"]
        direction TB
        Adapters["lib/interface_adapters: LevelDtoMapper, PlayerProgressJsonMapper"]
        Infra["lib/infrastructure: HTTP clients, SharedPreferences repositories,
        AppAudioService/NoOpAudioService (contextual SFX, background music, per-level countdown)"]
    end
    subgraph L2["Application"]
        direction TB
        UseCases["Use cases: LoadLevels, StartGame, FireArrow, RecordVictory (also evaluates
        collectible unlocks and syncs them), SyncPendingProgress, PullRemoteProgress, Login/Register/Logout"]
        AudioPort["IAudioService (port)"]
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
├── progress/          # Player progress per level, remote merge logic, meta-collectible catalog and unlock policy
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

### Collectibles

`MetaCollectibleCatalog` (`lib/domain/progress/services/`) is a static catalog of
gallery items, one per even-numbered milestone level plus an exclusive item for the
final level. `MetaCollectibleUnlockPolicy.shouldUnlock` decides whether completing a
level grants its collectible — it requires a perfect run (3 stars and the maximum
possible score for that board, computed from arrow count). `RecordVictoryUseCase` calls
the policy on every win, records the unlock on `PlayerProgress` (`unlockCollectible`),
and immediately syncs it to the backend's `POST /progress/collectibles/sync`
(`ProgressApiClient.syncCollectibles`); `PullRemoteProgressUseCase` merges server-side
unlocks back in (`PlayerProgress.mergeRemoteCollectibles`), so the gallery
(`CollectiblesScreen`) stays consistent across devices the same way level progress does.

### Class Diagram

Main classes across all four layers (color-coded), their relationships
(inheritance, interface implementation, association/composition), and the
design patterns applied. Low-level UI widgets are intentionally excluded;
screen controllers (presenters) are included. Editable source:
[`docs/architecture/class-diagram.mmd`](docs/architecture/class-diagram.mmd).

```mermaid
classDiagram
    direction TB
    class Cell { <<abstract>> }
    class Board {
        +Identifier id
        +BoardDimension dimension
        +Cell[] cells
        +Arrow[] arrows
        +cellAt(position) Cell
        +arrowIdAt(position) Identifier
        +placeArrowSegments(arrow) Board
        +applyArrowUpdate(arrow) Board
        +isCleared() bool
        +withDomainEvent(event) Board
        +pullDomainEvents() Board
    }
    class Arrow {
        +Identifier id
        +Position position
        +ArrowDirection direction
        +ArrowState state
        +Position[] body
        +occupies(position) bool
    }
    Board "1" o-- "0..*" Arrow
    Board ..> Cell

    class ArrowMovementEngine { +attemptMove(board, arrowId) MoveResult }
    class ICollisionValidator {
        <<interface>>
        +isBlocked(board, arrow) bool
    }
    class CollisionValidator
    ICollisionValidator <|.. CollisionValidator
    ArrowMovementEngine ..> ICollisionValidator

    class CellFactory { +createCell(type) Cell }
    class BoardFactory { +createBoard(definition) Board }
    CellFactory ..> Cell : creates (Factory Method)
    BoardFactory ..> CellFactory
    BoardFactory ..> Board : creates (Factory Method)

    class LevelDifficulty {
        <<enumeration>>
        easy
        medium
        hard
        expert
    }
    class Level {
        +Identifier id
        +int levelNumber
        +LevelDifficulty difficulty
        +LevelBoardDefinition boardDefinition
        +int parMoves
        +int optimalMoves
        +buildInitialBoard(factory) Board
    }
    Level --> LevelDifficulty
    Level ..> BoardFactory
    class LevelFactory { +fromJson(json) Level }
    class ShortestPathCalculator { +calculateMinimumMoves(board) int }
    class StarRatingCalculator { +calculate(moves, optimalMoves) StarRating }
    LevelFactory ..> Level : creates (Factory Method)
    LevelFactory ..> ShortestPathCalculator

    class GameStatus {
        <<enumeration>>
        ready
        inProgress
        won
        lost
        paused
    }
    class Game {
        +Identifier id
        +Identifier playerId
        +Level level
        +Board board
        +GameStatus status
        +int moveCount
        +int score
        +StarRating starsEarned
        +performMove(arrowId, engine) MoveResult
        +pause() Game
        +resume() Game
        +isWon() bool
        +isLost() bool
    }
    Game "1" *-- "1" Board
    Game "1" *-- "1" Level
    Game --> GameStatus
    Game ..> ArrowMovementEngine
    Game ..> StarRatingCalculator

    class PlayerProfile
    class PlayerStatistics
    PlayerProfile "1" *-- "1" PlayerStatistics

    class LevelProgressStatus {
        <<enumeration>>
        locked
        unlocked
        completed
    }
    class LevelProgress {
        +Identifier levelId
        +LevelProgressStatus status
        +int bestMoveCount
        +StarRating bestStars
        +recordCompletion(moves, time, stars) LevelProgress
        +unlock() LevelProgress
    }
    class PlayerProgress {
        +Identifier playerId
        +Map~Identifier,LevelProgress~ levels
        +Set~string~ unlockedCollectibles
        +completeLevel(levelId, ...) PlayerProgress
        +unlockLevel(levelId) PlayerProgress
        +mergeRemoteLevel(levelId, remoteMoves, remoteTime, remoteCompleted) PlayerProgress
        +unlockCollectible(collectibleId) PlayerProgress
        +mergeRemoteCollectibles(remoteCollectibleIds) PlayerProgress
    }
    PlayerProgress "1" *-- "many" LevelProgress
    LevelProgress --> LevelProgressStatus

    class MetaCollectibleKind {
        <<enumeration>>
        unlockable
        finalLevel
        comingSoon
    }
    class MetaCollectible {
        +string id
        +MetaCollectibleKind kind
        +int milestoneLevelNumber
        +string assetPath
    }
    class MetaCollectibleCatalog {
        <<static>>
        +forCompletedLevel(levelNumber) MetaCollectible
    }
    class MetaCollectibleUnlockPolicy {
        <<static>>
        +shouldUnlock(levelNumber, starsEarned, score, level) bool
        +collectibleForLevel(levelNumber) MetaCollectible
    }
    MetaCollectible --> MetaCollectibleKind
    MetaCollectibleCatalog ..> MetaCollectible : creates
    MetaCollectibleUnlockPolicy ..> MetaCollectibleCatalog

    class ILevelRepository {
        <<interface>>
        +findAll() Level[]
        +findById(id) Level
    }
    class IGameRepository {
        <<interface>>
        +save(game) void
        +findById(id) Game
    }
    class IPlayerProgressRepository {
        <<interface>>
        +save(progress) void
        +findByPlayerId(id) PlayerProgress
    }
    class IPendingSyncRepository {
        <<interface>>
        +add(entry) void
        +loadAll() PendingSyncEntry[]
        +saveAll(entries) void
    }
    class IAudioService {
        <<interface>>
        +ensureAudioUnlocked() void
        +playButtonClick() void
        +playArrowExtracted() void
        +playMovementNotAllowed() void
        +playLevelCleared() void
        +playNoMovementsLeft() void
        +playTimeUp() void
        +startBackgroundMusic() void
        +stopBackgroundMusic() void
    }

    class LoadLevelsUseCase { +execute() Level[] }
    class StartGameUseCase { +execute(gameId, playerId, level) Game }
    class FireArrowUseCase { +execute(game, position) MoveOutcome }
    class RecordVictoryUseCase { +execute(game, session) RecordVictoryResult }
    RecordVictoryUseCase ..> MetaCollectibleUnlockPolicy
    RecordVictoryUseCase ..> MetaCollectible
    class SyncPendingProgressUseCase { +execute(session) void }
    class PullRemoteProgressUseCase { +execute(session) PlayerProgress }
    class LoginUserUseCase
    class RegisterUserUseCase
    class EnsureInitialProgressUseCase

    LoadLevelsUseCase ..> ILevelRepository
    StartGameUseCase ..> IGameRepository
    FireArrowUseCase ..> IGameRepository
    FireArrowUseCase ..> ArrowMovementEngine
    RecordVictoryUseCase ..> IPlayerProgressRepository
    RecordVictoryUseCase ..> ILevelRepository
    RecordVictoryUseCase ..> IPendingSyncRepository
    SyncPendingProgressUseCase ..> IPendingSyncRepository
    PullRemoteProgressUseCase ..> IPlayerProgressRepository
    PullRemoteProgressUseCase ..> ILevelRepository
    PullRemoteProgressUseCase ..> PlayerProgress : uses mergeRemoteLevel

    class LevelDtoMapper {
        +fromDto(dto) Level
        +fromJson(json) Level
    }
    LevelDtoMapper ..> Level : adapts (Adapter)
    LoadLevelsUseCase ..> LevelDtoMapper

    class RemoteLevelRepository
    class CachedLevelRepository { +findAll() Level[] }
    class SharedPreferencesPlayerProgressRepository
    class SharedPreferencesPendingSyncRepository
    class AppAudioService {
        +ensureAudioUnlocked() void
        +startBackgroundMusic() void
    }
    class NoOpAudioService
    ILevelRepository <|.. RemoteLevelRepository
    ILevelRepository <|.. CachedLevelRepository
    CachedLevelRepository ..> RemoteLevelRepository : wraps (Decorator)
    CachedLevelRepository ..> LevelDtoMapper
    IPlayerProgressRepository <|.. SharedPreferencesPlayerProgressRepository
    IPendingSyncRepository <|.. SharedPreferencesPendingSyncRepository
    IAudioService <|.. AppAudioService
    IAudioService <|.. NoOpAudioService : (test double)

    class GameController {
        +startGame(level) void
        +onCellTapped(position) void
    }
    class LevelSelectController {
        +load() void
        +isOffline bool
    }
    class AuthSessionController {
        +login(username, password) bool
        +register(username, password) bool
    }
    class CollectiblesScreen
    class AudioScope { +of(context) IAudioService }
    AudioScope ..> IAudioService : provides (InheritedWidget)
    CollectiblesScreen ..> PlayerProgress
    CollectiblesScreen ..> MetaCollectibleCatalog
    GameController ..> StartGameUseCase
    GameController ..> FireArrowUseCase
    GameController ..> RecordVictoryUseCase
    GameController ..> IAudioService : contextual SFX + countdown
    LevelSelectController ..> LoadLevelsUseCase
    LevelSelectController ..> SyncPendingProgressUseCase
    LevelSelectController ..> PullRemoteProgressUseCase
    AuthSessionController ..> LoginUserUseCase
    AuthSessionController ..> RegisterUserUseCase

    class AppContainer { <<composition root>> }
    AppContainer ..> CachedLevelRepository
    AppContainer ..> SharedPreferencesPlayerProgressRepository
    AppContainer ..> SharedPreferencesPendingSyncRepository
    AppContainer ..> AppAudioService
    AppContainer ..> GameController
    AppContainer ..> LevelSelectController
    AppContainer ..> AuthSessionController

    classDef domain fill:#e8f4ea,stroke:#2e7d32,color:#1b3a1e
    classDef application fill:#e8eef8,stroke:#1565c0,color:#0d2a4d
    classDef adapters fill:#fdf3e2,stroke:#ef6c00,color:#5c3600
    classDef infrastructure fill:#f8e8ee,stroke:#ad1457,color:#4d0d24
    classDef presentation fill:#efe6fa,stroke:#6a1b9a,color:#33064d
    cssClass "Cell,Board,Arrow,ArrowMovementEngine,ICollisionValidator,CollisionValidator,CellFactory,BoardFactory,LevelDifficulty,Level,LevelFactory,ShortestPathCalculator,StarRatingCalculator,GameStatus,Game,PlayerProfile,PlayerStatistics,LevelProgressStatus,LevelProgress,PlayerProgress,MetaCollectibleKind,MetaCollectible,MetaCollectibleCatalog,MetaCollectibleUnlockPolicy,ILevelRepository,IGameRepository,IPlayerProgressRepository,IPendingSyncRepository" domain
    cssClass "LoadLevelsUseCase,StartGameUseCase,FireArrowUseCase,RecordVictoryUseCase,SyncPendingProgressUseCase,PullRemoteProgressUseCase,LoginUserUseCase,RegisterUserUseCase,EnsureInitialProgressUseCase,IAudioService" application
    cssClass "LevelDtoMapper" adapters
    cssClass "RemoteLevelRepository,CachedLevelRepository,SharedPreferencesPlayerProgressRepository,SharedPreferencesPendingSyncRepository,AppAudioService,NoOpAudioService,AppContainer" infrastructure
    cssClass "GameController,LevelSelectController,AuthSessionController,CollectiblesScreen,AudioScope" presentation
```

## Design Patterns

| Pattern | Category | Where |
|---|---|---|
| **Aggregate Root** | — (DDD) | `Level`, `Game`, `PlayerProfile`, `PlayerProgress` |
| **Value Object** | — (DDD) | `Position`, `Direction`, `StarRating`, `LevelBoardDefinition`, etc. |
| **Factory Method** | Creational | `LevelFactory`, `BoardFactory`, `CellFactory` |
| **Decorator** | Structural | `CachedLevelRepository` wraps the remote source with a write-through local cache behind the same `ILevelRepository` port; `LoggingFireArrowUseCaseDecorator` wraps `FireArrowUseCase` behind `IFireArrowUseCase` to add logging (AOP) |
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

Cross-cutting concerns are kept out of business logic via composition (the Decorator
pattern applied to SOLID's DIP, no AOP library), without any use case importing a
logger or catching network errors on its own:

1. **Logging & tracing** — [`LoggingFireArrowUseCaseDecorator`](lib/application/use_cases/logging_fire_arrow_use_case_decorator.dart)
   wraps [`FireArrowUseCase`](lib/application/use_cases/fire_arrow_use_case.dart) behind
   the extracted `IFireArrowUseCase` port and logs the board state (arrows remaining,
   move count, game status) before and after every shot, plus elapsed time and failures
   — `FireArrowUseCase` itself contains zero logging code, and `GameController` depends
   only on the `IFireArrowUseCase` interface, unaware it's talking to a decorated
   instance. Wired in the composition root (`AppContainer.buildGameController()`), with
   `IUseCaseLogger` as the swappable logging port (`ConsoleUseCaseLogger` by default).
2. **Domain events** — `Board.withDomainEvent()` / `Board.pullDomainEvents()` let
   `ArrowMovementEngine` raise `ArrowBlockedEvent`/`ArrowExtractedEvent` on every move,
   decoupling notification from the movement logic itself.
3. **Offline resilience as a decorator** — `CachedLevelRepository` transparently adds
   caching/fallback behavior around the remote level source; no use case or screen
   needs to know whether data came from the network or the cache.
4. **Best-effort sync retry** — `SyncPendingProgressUseCase` and `PullRemoteProgressUseCase`
   run as a side effect of `LevelSelectController.load()` and swallow their own
   failures, so a flaky connection never surfaces as a crash or a blocked screen — the
   UI just shows an "offline" notice instead of an error.

## Prebuilt Executables (Android / iOS)

Prebuilt binaries are published on the
[Releases](https://github.com/Mianjoy/Arrow-Maze-Escape-Puzzle/releases) page for
anyone who wants to try the app without building it from source. Both are already
configured to talk to a backend hosted on Render, so no local setup is required.

- **Android:** download the `.apk` and install it on any Android device (enable
  "install from unknown sources" for this one file if prompted).
- **iOS:** download the `.zip` and follow the instructions in the release notes to
  run it on the iOS Simulator (requires a Mac with Xcode; no Apple Developer account
  needed, since the Simulator does not require code signing).

> The backend runs on Render's free tier, which puts the service to sleep after a
> period of inactivity. The first request after idling (e.g. the first login) may
> take a few extra seconds while it wakes up — this is expected, not an error.

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
