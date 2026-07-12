import 'package:flutter/material.dart';

/// Puerto de preferencias de la aplicación (idioma y audio).
///
/// Aísla la capa de presentación de `SharedPreferences` u otro almacén local.
abstract interface class IAppSettings {
  /// Indica si la música de fondo está silenciada (no afecta efectos de juego).
  bool get isMuted;

  /// Indica si todos los efectos de sonido del juego están silenciados
  /// (clic de botones, movimiento bloqueado, flecha extraída, victoria,
  /// derrota). No afecta la música de fondo (ver [isMuted]).
  bool get isEffectsMuted;

  /// Locale activo de la interfaz (`en` o `es`).
  Locale get locale;

  /// Indica si ya se mostró (u omitió) el tutorial interactivo del nivel 1.
  bool get hasSeenTutorial;

  /// Carga las preferencias persistidas (llamar al arrancar la app).
  Future<void> load();

  /// Activa o desactiva el silencio de la música de fondo (no afecta efectos).
  Future<void> setMuted(bool muted);

  /// Activa o desactiva el silencio de todos los efectos de sonido del
  /// juego (ver [isEffectsMuted]).
  Future<void> setEffectsMuted(bool muted);

  /// Cambia el idioma de la interfaz y lo persiste.
  Future<void> setLocale(Locale locale);

  /// Marca el tutorial interactivo del nivel 1 como visto (u omitido), o
  /// lo reactiva pasando `false` (p. ej. desde Ajustes, para repasarlo).
  Future<void> setHasSeenTutorial(bool seen);
}
