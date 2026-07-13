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

Screens from the Android build (Spanish UI, synced with the backend on Render):

| Screen | Description |
|--------|-------------|
| Home | Title, **Play** button, shortcuts to collectibles, leaderboard and settings |
| Level select | Catalog with completion checkmarks, difficulty, par moves and stars |
| Gameplay | Board with arrows, move/score counter and per-level countdown timer |
| Victory | Score, stars earned, progress saved, next level / leaderboard actions |
| Collectibles | Gallery unlocked every 2 levels with 3 stars; exclusive final-level reward |
| Leaderboard | Global ranking per level (score, moves, time) |

<p align="center">
  <img src="docs/screenshots/01-home.png" alt="Home screen" width="220" />
  <img src="docs/screenshots/02-level-select.png" alt="Level selection" width="220" />
  <img src="docs/screenshots/03-gameplay.png" alt="Gameplay — La Escuadra" width="220" />
</p>
<p align="center">
  <img src="docs/screenshots/04-victory.png" alt="Level cleared" width="220" />
  <img src="docs/screenshots/05-collectibles.png" alt="Collectibles gallery" width="220" />
  <img src="docs/screenshots/06-leaderboard.png" alt="Leaderboard" width="220" />
</p>

## Architecture

Four Clean Architecture layers, dependencies pointing inward (outer layers depend on
inner ones, never the reverse):

```mermaid
flowchart TB
    %% Clean Architecture — frontend Arrow Maze.
    %% Outer layers depend on inner layers only (dependency rule).

    subgraph Legend["Legend — layer colors"]
        direction LR
        LgD["#e8f4ea Domain"] ~~~ LgA["#e8eef8 Application"] ~~~ LgAd["#fdf3e2 Adapters"] ~~~ LgI["#f8e8ee Infrastructure"] ~~~ LgP["#efe6fa Presentation"]
    end

    subgraph L4["Layer 4 — Presentation"]
        direction TB
        Screens["Screens: Home, LevelSelect, Game, Victory, Defeat,
        Auth (login/register), Leaderboard, Settings, Collectibles gallery"]
        Controllers["Controllers (ChangeNotifier): Game, LevelSelect, AuthSession,
        Leaderboard, AppSettings"]
        AudioScope["AudioScope (provides IAudioService to widget tree)"]
    end

    subgraph L3["Layer 3 — Infrastructure & Interface Adapters"]
        direction TB
        Adapters["LevelDtoMapper, PlayerProgressJsonMapper"]
        HttpClients["LevelApiClient, ProgressApiClient, AuthApiClient, LeaderboardApiClient"]
        LocalRepos["SharedPreferences repositories, AppAudioService / NoOpAudioService"]
    end

    subgraph L2["Layer 2 — Application"]
        direction TB
        UseCases["LoadLevels, StartGame, FireArrow (via IFireArrowUseCase),
        RecordVictory, SyncPendingProgress, PullRemoteProgress,
        Login/Register/Logout/RestoreSession, GetLeaderboard"]
        AopDecorator["LoggingFireArrowUseCaseDecorator (AOP logging)"]
        Ports["IAudioService, IAuthApiClient, IProgressApiClient, ILeaderboardApiClient, ITokenStorage"]
    end

    subgraph L1["Layer 1 — Domain"]
        direction TB
        Entities["Board, Game, Level, PlayerProfile, PlayerProgress,
        meta-collectibles, domain events"]
    end

    L4 -->|depends on| L3
    L3 -->|depends on| L2
    L2 -->|depends on| L1

    classDef domain fill:#e8f4ea,stroke:#2e7d32,color:#1b3a1e
    classDef app fill:#e8eef8,stroke:#1565c0,color:#0d2a4d
    classDef adapters fill:#fdf3e2,stroke:#ef6c00,color:#5c3600
    classDef infra fill:#f8e8ee,stroke:#ad1457,color:#4d0d24
    classDef presentation fill:#efe6fa,stroke:#6a1b9a,color:#33064d
    classDef legend fill:#f5f5f5,stroke:#9e9e9e,color:#333

    class Entities domain
    class UseCases,AopDecorator,Ports app
    class Adapters,HttpClients,LocalRepos adapters
    class Screens,Controllers,AudioScope presentation
    class LgD,LgA,LgAd,LgI,LgP legend
```

![Clean Architecture layers (static export)](docs/architecture/clean-architecture.png)

Source: [`docs/architecture/clean-architecture.mmd`](docs/architecture/clean-architecture.mmd) (editable). Regenerate README embeds with `python scripts/sync-readme-diagrams.py`.

| Layer | Responsibility | Status |
|---|---|---|
| **Domain** | Entities, aggregates, value objects, domain services, events, repository ports | ✅ Implemented |
| **Application** | Use cases, AOP decorator (`LoggingFireArrowUseCaseDecorator`), HTTP/audio ports | ✅ Implemented |
| **Infrastructure / Interface Adapters** | API clients, DTO mappers, SharedPreferences repos, audio service | ✅ Implemented |
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
[`docs/architecture/class-diagram.mmd`](docs/architecture/class-diagram.mmd). Regenerate README embeds with `python scripts/sync-readme-diagrams.py`.

```mermaid
classDiagram
    direction TB

    %% Arrow Maze Client — Class Diagram
    %% Layer colors: green=Domain, blue=Application, orange=Adapters,
    %% pink=Infrastructure, purple=Presentation
    %% Patterns: Factory Method, Decorator, Adapter, Repository/DIP,
    %% State (GameStatus), Domain Event, Observer (domain events)

    %% ----- Domain: board -----
    class Cell {
        <<abstract>>
    }
    class Board {
        +Identifier id
        +BoardDimension dimension
        +Cell[] cells
        +Arrow[] arrows
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
    CellFactory ..> Cell : Factory Method
    BoardFactory ..> CellFactory
    BoardFactory ..> Board : Factory Method

    %% ----- Domain: level -----
    class LevelDifficulty {
        <<enumeration>>
        easy medium hard expert
    }
    class Level {
        +Identifier id
        +int levelNumber
        +LevelDifficulty difficulty
        +int parMoves
        +int optimalMoves
        +buildInitialBoard(factory) Board
    }
    Level --> LevelDifficulty
    Level ..> BoardFactory

    class LevelFactory { +fromJson(json) Level }
    class ShortestPathCalculator { +calculateMinimumMoves(board) int }
    class StarRatingCalculator { +calculate(moves, optimal) StarRating }
    LevelFactory ..> Level : Factory Method

    %% ----- Domain: game (State pattern) -----
    class GameStatus {
        <<enumeration>>
        <<State>>
        ready inProgress won lost paused
    }
    class Game {
        +GameStatus status
        +int moveCount
        +int score
        +performMove(arrowId, engine) MoveResult
        +pause() Game
        +resume() Game
        +isWon() bool
        +isLost() bool
    }
    Game "1" *-- "1" Board
    Game "1" *-- "1" Level
    Game --> GameStatus : State

    %% ----- Domain: player & progress -----
    class PlayerProfile
    class PlayerStatistics
    PlayerProfile "1" *-- "1" PlayerStatistics

    class LevelProgress {
        +Identifier levelId
        +LevelProgressStatus status
        +recordCompletion(...) LevelProgress
    }
    class PlayerProgress {
        +Identifier playerId
        +Map levels
        +Set unlockedCollectibles
        +mergeRemoteLevel(...) PlayerProgress
        +mergeRemoteCollectibles(...) PlayerProgress
    }
    PlayerProgress "1" *-- "many" LevelProgress

    class MetaCollectibleCatalog { <<static>> +forCompletedLevel(n) MetaCollectible }
    class MetaCollectibleUnlockPolicy { <<static>> +shouldUnlock(...) bool }

    %% ----- Domain: repository ports -----
    class ILevelRepository {
        <<interface>>
        +findAll() Level[]
        +findById(id) Level
    }
    class IGameRepository {
        <<interface>>
        +save(game) void
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
    }

    %% ----- Application: ports & use cases -----
    class IAudioService {
        <<interface>>
        +playArrowExtracted() void
        +startBackgroundMusic() void
    }
    class IAuthApiClient {
        <<interface>>
        +register(dto) AuthResult
        +login(dto) AuthResult
    }
    class IProgressApiClient {
        <<interface>>
        +syncProgress(dto) void
        +syncCollectibles(ids) void
        +getProgress() PlayerProgressDto
    }
    class ILeaderboardApiClient {
        <<interface>>
        +getLeaderboard(levelId) LeaderboardEntry[]
    }
    class ITokenStorage {
        <<interface>>
        +saveToken(token) void
        +clear() void
    }
    class IFireArrowUseCase {
        <<interface>>
        +execute(game, position) MoveOutcome
    }

    class LoadLevelsUseCase { +execute() Level[] }
    class StartGameUseCase { +execute(...) Game }
    class FireArrowUseCase { +execute(game, position) MoveOutcome }
    class LoggingFireArrowUseCaseDecorator { +execute(game, position) MoveOutcome }
    class RecordVictoryUseCase { +execute(game, session) RecordVictoryResult }
    class SyncPendingProgressUseCase { +execute(session) void }
    class PullRemoteProgressUseCase { +execute(session) PlayerProgress }
    class LoginUserUseCase { +execute(dto) bool }
    class RegisterUserUseCase { +execute(dto) bool }
    class LogoutUserUseCase { +execute() void }
    class GetLeaderboardUseCase { +execute(levelId) entries }
    class EnsureInitialProgressUseCase { +execute(playerId) void }

    IFireArrowUseCase <|.. FireArrowUseCase
    IFireArrowUseCase <|.. LoggingFireArrowUseCaseDecorator : Decorator AOP
    LoggingFireArrowUseCaseDecorator o-- FireArrowUseCase : wraps

    LoadLevelsUseCase ..> ILevelRepository
    StartGameUseCase ..> IGameRepository
    FireArrowUseCase ..> IGameRepository
    FireArrowUseCase ..> ArrowMovementEngine
    RecordVictoryUseCase ..> IPlayerProgressRepository
    RecordVictoryUseCase ..> IPendingSyncRepository
    RecordVictoryUseCase ..> IProgressApiClient
    RecordVictoryUseCase ..> MetaCollectibleUnlockPolicy
    SyncPendingProgressUseCase ..> IPendingSyncRepository
    SyncPendingProgressUseCase ..> IProgressApiClient
    PullRemoteProgressUseCase ..> IPlayerProgressRepository
    PullRemoteProgressUseCase ..> IProgressApiClient
    LoginUserUseCase ..> IAuthApiClient
    LoginUserUseCase ..> ITokenStorage
    RegisterUserUseCase ..> IAuthApiClient
    RegisterUserUseCase ..> ITokenStorage
    LogoutUserUseCase ..> ITokenStorage
    GetLeaderboardUseCase ..> ILeaderboardApiClient

    %% ----- Interface Adapters -----
    class LevelDtoMapper { +fromDto(dto) Level }
    class PlayerProgressJsonMapper { +toJson(progress) String }
    LoadLevelsUseCase ..> LevelDtoMapper
    LevelDtoMapper ..> Level : Adapter

    %% ----- Infrastructure -----
    class RemoteLevelRepository
    class CachedLevelRepository { +findAll() Level[] }
    class SharedPreferencesPlayerProgressRepository
    class SharedPreferencesPendingSyncRepository
    class LevelApiClient
    class ProgressApiClient
    class AuthApiClient
    class LeaderboardApiClient
    class AppAudioService
    class NoOpAudioService

    ILevelRepository <|.. RemoteLevelRepository
    ILevelRepository <|.. CachedLevelRepository
    CachedLevelRepository ..> RemoteLevelRepository : Decorator
    CachedLevelRepository ..> LevelApiClient
    CachedLevelRepository ..> LevelDtoMapper
    IPlayerProgressRepository <|.. SharedPreferencesPlayerProgressRepository
    SharedPreferencesPlayerProgressRepository ..> PlayerProgressJsonMapper
    IPendingSyncRepository <|.. SharedPreferencesPendingSyncRepository
    IAuthApiClient <|.. AuthApiClient
    IProgressApiClient <|.. ProgressApiClient
    ILeaderboardApiClient <|.. LeaderboardApiClient
    IAudioService <|.. AppAudioService
    IAudioService <|.. NoOpAudioService

    %% ----- Presentation -----
    class GameController { +onCellTapped(position) void }
    class LevelSelectController { +load() void }
    class AuthSessionController { +login() bool +logout() void }
    class LeaderboardController { +load(levelId) void }
    class AppSettingsController { +toggleSound() void }

    GameController ..> StartGameUseCase
    GameController ..> IFireArrowUseCase
    GameController ..> RecordVictoryUseCase
    GameController ..> IAudioService
    LevelSelectController ..> LoadLevelsUseCase
    LevelSelectController ..> SyncPendingProgressUseCase
    LevelSelectController ..> PullRemoteProgressUseCase
    AuthSessionController ..> LoginUserUseCase
    AuthSessionController ..> RegisterUserUseCase
    AuthSessionController ..> LogoutUserUseCase
    LeaderboardController ..> GetLeaderboardUseCase

    class AppContainer { <<composition root>> }
    AppContainer ..> CachedLevelRepository
    AppContainer ..> GameController
    AppContainer ..> LevelSelectController
    AppContainer ..> AuthSessionController
    AppContainer ..> LoggingFireArrowUseCaseDecorator

    %% ----- Layer legend -----
    classDef domain fill:#e8f4ea,stroke:#2e7d32,color:#1b3a1e
    classDef application fill:#e8eef8,stroke:#1565c0,color:#0d2a4d
    classDef adapters fill:#fdf3e2,stroke:#ef6c00,color:#5c3600
    classDef infrastructure fill:#f8e8ee,stroke:#ad1457,color:#4d0d24
    classDef presentation fill:#efe6fa,stroke:#6a1b9a,color:#33064d

    cssClass "Cell,Board,Arrow,ArrowMovementEngine,ICollisionValidator,CollisionValidator,CellFactory,BoardFactory,LevelDifficulty,Level,LevelFactory,ShortestPathCalculator,StarRatingCalculator,GameStatus,Game,PlayerProfile,PlayerStatistics,LevelProgress,PlayerProgress,MetaCollectibleCatalog,MetaCollectibleUnlockPolicy,ILevelRepository,IGameRepository,IPlayerProgressRepository,IPendingSyncRepository" domain
    cssClass "IAudioService,IAuthApiClient,IProgressApiClient,ILeaderboardApiClient,ITokenStorage,IFireArrowUseCase,LoadLevelsUseCase,StartGameUseCase,FireArrowUseCase,LoggingFireArrowUseCaseDecorator,RecordVictoryUseCase,SyncPendingProgressUseCase,PullRemoteProgressUseCase,LoginUserUseCase,RegisterUserUseCase,LogoutUserUseCase,GetLeaderboardUseCase,EnsureInitialProgressUseCase" application
    cssClass "LevelDtoMapper,PlayerProgressJsonMapper" adapters
    cssClass "RemoteLevelRepository,CachedLevelRepository,SharedPreferencesPlayerProgressRepository,SharedPreferencesPendingSyncRepository,LevelApiClient,ProgressApiClient,AuthApiClient,LeaderboardApiClient,AppAudioService,NoOpAudioService,AppContainer" infrastructure
    cssClass "GameController,LevelSelectController,AuthSessionController,LeaderboardController,AppSettingsController" presentation
```

![Class diagram (static export)](docs/architecture/class-diagram.png)

## Design Patterns

| Pattern | Category | Where |
|---|---|---|
| **Aggregate Root** | — (DDD) | `Level`, `Game`, `PlayerProfile`, `PlayerProgress` |
| **Value Object** | — (DDD) | `Position`, `Direction`, `StarRating`, `LevelBoardDefinition`, etc. |
| **Factory Method** | Creational | `LevelFactory`, `BoardFactory`, `CellFactory` |
| **Decorator** | Structural | `CachedLevelRepository` (offline cache); `LoggingFireArrowUseCaseDecorator` wraps `FireArrowUseCase` behind `IFireArrowUseCase` (AOP logging) |
| **Adapter** | Structural | `LevelDtoMapper` (wire format ↔ domain), `PlayerProgressJsonMapper` |
| **Repository (DIP)** | Structural | Interfaces in `lib/domain/repositories/` and `lib/application/ports/` |
| **State** | Behavioral | `GameStatus` drives `Game` lifecycle (`ready`, `inProgress`, `won`, `lost`, `paused`) |
| **Domain Event** | Behavioral | `GameWonEvent`, `ArrowExtractedEvent`, `ArrowBlockedEvent`, raised via `Board.pullDomainEvents()` |
| **Observer** | Behavioral | Domain events decouple board movement from scoring/audio/UI reactions |
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
