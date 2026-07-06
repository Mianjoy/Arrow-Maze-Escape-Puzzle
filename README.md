# Arrow Maze Escape Puzzle

Juego de puzzle tipo *Arrow Maze* donde el jugador debe extraer todas las flechas del tablero
moviéndolas en la dirección que apuntan, sin colisiones.

## Arquitectura

El proyecto sigue **Clean Architecture** con separación estricta de capas:

| Capa | Responsabilidad | Estado |
|------|-----------------|--------|
| **Domain** | Entidades, agregados, value objects, servicios de dominio, eventos e interfaces de repositorio | ✅ Implementada |
| Application | Casos de uso y orquestación | Pendiente |
| Infrastructure | Persistencia, APIs, adaptadores | Pendiente |
| Presentation | UI (Flutter) | Pendiente |

## Capa de Dominio

```
lib/domain/
├── shared/           # Value objects, enums y excepciones transversales
├── player/           # Jugador y perfil
├── board/            # Board, Cell, Arrow (entidades de estado)
├── level/            # Level (agregado), carga JSON, estrellas
├── game/             # Game (agregado de sesión activa)
├── progress/         # Progreso del jugador por nivel
└── repositories/     # Contratos de persistencia (interfaces)
```

### Agregados raíz

| Agregado | Responsabilidad |
|----------|-----------------|
| **Level** | Definición del nivel desde JSON, tablero inicial y ruta óptima |
| **Game** | Coordina movimientos, victoria, derrota y estrellas durante la partida |
| **PlayerProfile** | Perfil y estadísticas del jugador |
| **PlayerProgress** | Progreso y mejores estrellas por nivel |

### Entidades (no agregados)

- **Board** — Estado del tablero (celdas y flechas); no orquesta reglas de juego.
- **Cell**, **Arrow**, **Player** — Entidades de soporte.

### Carga de niveles desde JSON

Cada nivel se define en un archivo JSON con este esquema:

```json
{
  "id": "level-001",
  "difficulty": "easy",
  "board": {
    "rows": 3,
    "cols": 3,
    "cells": [
      { "row": 0, "col": 0, "direction": "right" }
    ]
  },
  "playerStart": { "row": 1, "col": 1 },
  "parMoves": 6,
  "timeLimit": 120
}
```

Ver ejemplo en [`docs/levels/example_level.json`](docs/levels/example_level.json).

`LevelFactory` parsea el JSON, calcula la ruta óptima con `ShortestPathCalculator` y produce un agregado `Level` listo para jugar.

### Sistema de estrellas

| Movimientos usados | Estrellas |
|--------------------|-----------|
| ≤ ruta óptima | ⭐⭐⭐ (3) |
| Intermedio (entre óptimo y par) | ⭐⭐ (2) |
| = parMoves (máximo sin perder) | ⭐ (1) |
| > parMoves | Derrota |

Si el jugador agota `parMoves` sin completar el nivel, `Game` transiciona a `GameStatus.lost` con el mensaje configurado en `GameLossMessage.movesExceeded`.

### Patrones de diseño aplicados

- **Aggregate Root** — `Level`, `Game`, `PlayerProfile`, `PlayerProgress`
- **Value Object** — `Position`, `StarRating`, `LevelBoardDefinition`, etc.
- **Factory** — `LevelFactory`, `BoardFactory`, `CellFactory`
- **Domain Service** — `ShortestPathCalculator`, `StarRatingCalculator`, `ArrowMovementEngine`
- **Repository** — Interfaces en `repositories/`
- **Domain Event** — `GameWonEvent`, `ArrowExtractedEvent`, etc.

## Uso de IA

Consulta el archivo [IA_USAGE.md](IA_USAGE.md) para el registro de interacciones con herramientas de IA durante el desarrollo.

## Requisitos

- Dart SDK >= 3.0.0
