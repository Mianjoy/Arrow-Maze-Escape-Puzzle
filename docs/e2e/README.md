# Pruebas E2E — Arrow Maze (Flutter ↔ Backend)

Este documento describe cómo validar el **Día 3** del plan de integración: catálogo remoto jugable de punta a punta.

## Automatizado (CI)

La suite vive en `test/e2e/` y se ejecuta con el resto de tests:

```bash
flutter test
# Solo E2E:
flutter test test/e2e
```

| Archivo | Qué valida |
|---------|------------|
| `remote_catalog_e2e_test.dart` | 15 niveles vía `RemoteLevelRepository` simulado |
| `wire_format_playability_e2e_test.dart` | Mapeo wire → partida, victoria greedy, derrota |
| `playable_flow_e2e_test.dart` | UI: lista → level-02 → victoria; level-09 → derrota |

El fixture `test/e2e/support/seed_catalog_fixture.dart` es espejo de `LEVEL_SEED_CATALOG` del backend.

## Manual (backend real)

### 1. Backend

```bash
cd BackEnd-ArrowMaze
npm run dev
curl http://localhost:3000/levels | jq length   # 15
```

### 2. Frontend (solo API, sin fallback a assets)

```bash
cd Arrow-Maze-Escape-Puzzle
flutter run -d chrome --dart-define=ASSET_FALLBACK=false
```

Opcional: `--dart-define=API_BASE_URL=http://10.0.2.2:3000` en emulador Android.

### 3. Checklist manual

- [ ] Pantalla de login/registro funciona contra `npm run dev`
- [ ] Tras login, lista muestra 15 niveles (`simple-1` … `level-15`)
- [ ] `level-02`: un toque → victoria → progreso sincronizado
- [ ] Botón **Leaderboard** en diálogo de victoria muestra ranking del nivel
- [ ] Logout redirige a `/login`
- [ ] `level-04`: tablero con muro visible
- [ ] `level-09`: se puede perder al agotar movimientos
- [ ] `level-15`: completable con varios disparos

## Sincronización fixture ↔ backend

Si se añaden niveles al seed en `BackEnd-ArrowMaze`, actualizar:

1. `src/infrastructure/persistence/seed/catalogEntries/*.ts`
2. `test/e2e/support/seed_catalog_fixture.dart` (o `test/fixtures/seed_catalog.json`)
3. `kSeedCatalogExpectedCount` en el fixture
