# Fixtures de contrato (auth, progress, leaderboard, levels, errores)

Estos archivos son fixtures compartidos, **bit-a-bit idénticos**, entre este
repo y `Arrow-Maze-Escape-Puzzle/docs/contract/fixtures/`. Cada uno
representa la forma real de una petición, respuesta o error HTTP en una
frontera compartida entre el backend y el cliente Flutter:

| Fixture | Frontera | Dirección |
|---------|----------|-----------|
| `auth-register-response.json` | `POST /auth/register` | Respuesta del backend |
| `auth-login-response.json` | `POST /auth/login` | Respuesta del backend |
| `progress-sync-request.json` | `POST /progress/sync` | Body enviado por el cliente |
| `progress-sync-response.json` | `POST /progress/sync` | Respuesta del backend |
| `progress-get-response.json` | `GET /progress` | Respuesta del backend |
| `leaderboard-response.json` | `GET /leaderboard/:levelId` | Respuesta del backend |
| `levels-get-response.json` | `GET /levels` | Respuesta del backend (un nivel de ejemplo del catálogo) |
| `error-401-unauthorized.json` | Cualquier ruta protegida sin JWT válido | Sobre de error del backend |
| `error-409-user-already-exists.json` | `POST /auth/register` con username duplicado | Sobre de error del backend |

(El fixture del contrato de nivel usado por `LevelJsonMapper`, `simple-1.json`,
vive aparte en `docs/levels/` por ser el mismo archivo que ya usa el catálogo
de niveles — ver `docs/levels/README.md`. `levels-get-response.json` es un
fixture distinto y más pequeño, pensado específicamente para el endpoint
`GET /levels`.)

## Por qué fixtures compartidos y no Pact

El enunciado del proyecto recomienda usar **Pact** (o herramienta
equivalente) para pruebas de contrato consumer-driven. Se evaluó
explícitamente y se descartó por un motivo concreto: **no existe un SDK
oficial o razonablemente mantenido de Pact para el lado consumidor en
Dart/Flutter** (el ecosistema de Pact es fuerte en JVM, .NET, JS/Node,
Python, Go y Ruby, pero no en Dart), por lo que adoptarlo tal cual
introduciría fricción y tooling desproporcionado para el alcance de un
proyecto semestral con dos repos independientes y sin pipeline de CI
compartido entre ambos.

En su lugar, se aplicó una **verificación de contrato equivalente y más
simple**, con tres componentes:

1. **Fixtures JSON compartidos**, idénticos en ambos repos, uno por cada
   frontera HTTP (tabla de arriba).
2. **Pruebas que ejercitan el código real** de cada lado contra esos
   fixtures — no una re-implementación de su forma. En el backend, con
   esquemas **Zod** (`tests/support/contractSchemas.ts`) que validan TIPOS
   y ausencia de campos extra (`.strict()`), no solo el conjunto de claves,
   aplicados tanto al fixture como a la respuesta real obtenida vía
   `supertest`. En el frontend, con los clientes HTTP reales
   (`AuthApiClient`, `ProgressApiClient`, `LeaderboardApiClient`,
   `LevelApiClient`) contra un `MockHttpClient` que reenvía el fixture.
3. **Verificación de sincronización entre repos** (`scripts/check-contract-fixtures-sync.sh`,
   corrido en CI): compara el hash SHA-256 de cada fixture de este repo
   contra su copia en el otro, para detectar si un lado editó un fixture
   sin replicar el cambio en el otro — la comprobación automática que
   Pact daría gratis vía su broker, aproximada aquí sin esa infraestructura.

Esto reproduce la garantía central de una prueba de contrato — que ambos
lados coinciden en la forma **y el tipo** de los datos que intercambian —
sin depender de un SDK de consumidor que no existe para este stack.

**Limitación aceptada**: a diferencia de Pact, no hay generación automática
del contrato desde el consumidor ni un broker central; la sincronización de
estos archivos entre los dos repos sigue siendo manual en el día a día —
`scripts/check-contract-fixtures-sync.sh` solo la **verifica** (y falla la
build si detecta una divergencia real), no la automatiza. En CI, si el otro
repo no es accesible (privado, sin red), el script lo reporta pero no hace
fallar el build por esa causa — no es un gate que deba poder tumbar el
pipeline por un problema de acceso ajeno a los fixtures en sí.
