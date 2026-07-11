import 'package:flutter/material.dart';

/// Puerto de preferencias de la aplicación (idioma y audio).
///
/// Aísla la capa de presentación de `SharedPreferences` u otro almacén local.
abstract interface class IAppSettings {
  /// Indica si la música de fondo está silenciada (no afecta efectos de juego).
  bool get isMuted;

  /// Indica si los efectos de resultado de partida están silenciados:
  /// victoria (nivel completado), derrota (sin movimientos o sin tiempo) y
  /// flecha extraída del tablero. No afecta la música de fondo ni el resto
  /// de efectos (clic de botones, movimiento bloqueado).
  bool get isEffectsMuted;

  /// Locale activo de la interfaz (`en` o `es`).
  Locale get locale;

  /// Carga las preferencias persistidas (llamar al arrancar la app).
  Future<void> load();

  /// Activa o desactiva el silencio de la música de fondo (no afecta efectos).
  Future<void> setMuted(bool muted);

  /// Activa o desactiva el silencio de los efectos de victoria, derrota y
  /// flecha extraída (ver [isEffectsMuted]).
  Future<void> setEffectsMuted(bool muted);

  /// Cambia el idioma de la interfaz y lo persiste.
  Future<void> setLocale(Locale locale);
}
