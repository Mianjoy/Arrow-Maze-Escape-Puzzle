# Audio assets

All sound files use **MP3** format, consumed via `audioplayers` and `AssetSource`.

Paths passed to `AssetSource` are **relative to this folder** (e.g. `audio/background.mp3`), without a leading `assets/` prefix — adding `assets/` twice causes 404 on Flutter Web.

| Carpeta / archivo | Uso |
|-------------------|-----|
| `background.mp3` | Música de fondo en bucle (silenciada con el toggle de mute) |
| `General_Tap/general_click_sound.mp3` | Clic en botones generales de la interfaz |
| `Tap_sound/tap_sound_1.mp3` … `tap_sound_5.mp3` | Sonido aleatorio al sacar una flecha del tablero |
| `Movement_Not_Allowe/not_allowed_movement.mp3` | Colisión de una flecha con otra flecha |
| `Level_Cleared/level_cleared.mp3` | Nivel completado con éxito (todas las flechas extraídas) |
| `times_up.mp3` | Tiempo del nivel agotado |
| `no_movements_left.mp3` | Movimientos del nivel agotados |

Tras añadir, convertir o renombrar archivos, reinicia la app por completo (no basta hot reload).
