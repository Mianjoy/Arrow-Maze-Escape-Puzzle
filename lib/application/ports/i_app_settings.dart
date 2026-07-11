import 'package:flutter/material.dart';

/// Puerto de preferencias de la aplicación (idioma y audio).
///
/// Aísla la capa de presentación de `SharedPreferences` u otro almacén local.
abstract interface class IAppSettings {
  /// Indica si la música de fondo está silenciada (no afecta efectos de juego).
  bool get isMuted;

  /// Locale activo de la interfaz (`en` o `es`).
  Locale get locale;

  /// Carga las preferencias persistidas (llamar al arrancar la app).
  Future<void> load();

  /// Activa o desactiva el silencio de la música de fondo (no afecta efectos).
  Future<void> setMuted(bool muted);

  /// Cambia el idioma de la interfaz y lo persiste.
  Future<void> setLocale(Locale locale);
}
