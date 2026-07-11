# Fixtures de contrato (auth, progress, leaderboard)

Estos archivos son fixtures compartidos, **bit-a-bit idénticos**, entre este
repo y `Arrow-Maze-Escape-Puzzle/docs/contract/fixtures/`. Cada uno
representa la forma real de una petición o respuesta HTTP en una frontera
compartida entre el backend y el cliente Flutter:

| Fixture | Frontera | Dirección |
|---------|----------|-----------|
| `auth-register-response.json` | `POST /auth/register` | Respuesta del backend |
| `auth-login-response.json` | `POST /auth/login` | Respuesta del backend |
| `progress-sync-request.json` | `POST /progress/sync` | Body enviado por el cliente |
| `progress-sync-response.json` | `POST /progress/sync` | Respuesta del backend |
| `progress-get-response.json` | `GET /progress` | Respuesta del backend |
| `leaderboard-response.json` | `GET /leaderboard/:levelId` | Respuesta del backend |

(El fixture del contrato de nivel, `simple-1.json`, vive aparte en
`docs/levels/` por ser el mismo archivo que ya usa el catálogo de niveles —
ver `docs/levels/README.md`.)

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
simple**: un fixture JSON idéntico en ambos repos por cada frontera HTTP
compartida, y en cada repo una prueba que ejercita el **código real** de ese
lado (esquema de validación Zod, ruta HTTP real vía `supertest`, o el
cliente HTTP real del frontend) contra ese mismo fixture. Esto reproduce la
garantía central de una prueba de contrato — que ambos lados coinciden en la
forma de los datos que intercambian — sin depender de un SDK de consumidor
que no existe para este stack.

**Limitación aceptada**: a diferencia de Pact, no hay generación automática
del contrato desde el consumidor ni verificación cruzada en un pipeline
compartido; la sincronización de estos archivos entre los dos repos es
manual. Quien edite un fixture aquí debe replicar el cambio en
`Arrow-Maze-Escape-Puzzle/docs/contract/fixtures/`, y viceversa.
