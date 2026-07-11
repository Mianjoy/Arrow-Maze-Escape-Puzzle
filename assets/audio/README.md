# Audio assets

All sound files use **WAV** format (PCM), consumed via `audioplayers` and `AssetSource`.

| Carpeta / archivo | Uso |
|-------------------|-----|
| `background.wav` | Música de fondo en bucle |
| `General_Tap/general_click_sound.wav` | Clic en botones generales de la interfaz |
| `Tap_sound/tap_sound_1.wav` … `tap_sound_5.wav` | Sonido aleatorio al sacar una flecha del tablero |
| `Movement_Not_Allowe/not_allowed_movement.wav` | Colisión de una flecha con otra flecha |
| `Level_Cleared/level_cleared.wav` | Nivel completado con éxito (todas las flechas extraídas) |
| `times_up.wav` | Tiempo del nivel agotado |
| `no_movements_left.wav` | Movimientos del nivel agotados |

Tras añadir, convertir o renombrar archivos, reinicia la app por completo (no basta hot reload).
