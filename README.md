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
├── board/            # Tablero, celdas, flechas y motor de movimiento
├── level/            # Niveles y configuración
├── game/             # Partida activa (sesión de juego)
├── progress/         # Progreso del jugador por nivel
└── repositories/     # Contratos de persistencia (interfaces)
```

### Entidades principales

- **Player** — Identidad y estadísticas del jugador.
- **Board** — Agregado raíz del tablero con celdas y flechas.
- **Cell** — Celda individual del grid.
- **Level** — Definición de un nivel (dimensiones, dificultad, flechas).

### Entidades adicionales (para revisión)

- **Arrow** — Flecha con dirección y estado en el tablero.
- **Game** — Sesión de juego activa que une jugador, nivel y tablero.
- **PlayerProgress** — Agregado de progreso desbloqueado/completado por nivel.

### Patrones de diseño aplicados

- **Aggregate Root** — `Board`, `Game`, `PlayerProfile`, `PlayerProgress`
- **Value Object** — `Position`, `Direction`, `Identifier`, etc.
- **Factory** — `BoardFactory`, `CellFactory`
- **Domain Service** — `ArrowMovementEngine`, `CollisionValidator`, `RandomBoardGenerator`
- **Repository** — Interfaces en `repositories/` (sin implementación)
- **Domain Event** — `ArrowExtractedEvent`, `ArrowBlockedEvent`, `GameWonEvent`

## Uso de IA

Consulta el archivo [IA_USAGE.md](IA_USAGE.md) para el registro de interacciones con herramientas de IA durante el desarrollo.

## Requisitos

- Dart SDK >= 3.0.0
