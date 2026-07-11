import 'package:flutter/material.dart';

import '../../application/ports/i_app_settings.dart';

/// Controlador observable de preferencias de la app (idioma y mute).
///
/// Notifica a la UI cuando cambian para reconstruir [MaterialApp] y [AppStringsScope].
class AppSettingsController extends ChangeNotifier {
  /// Crea el controlador con el puerto [settings] inyectado.
  AppSettingsController({required IAppSettings settings}) : _settings = settings;

  final IAppSettings _settings;

  /// Indica si la música de fondo está silenciada.
  bool get isMuted => _settings.isMuted;

  /// Indica si los efectos de victoria, derrota y flecha extraída están silenciados.
  bool get isEffectsMuted => _settings.isEffectsMuted;

  /// Locale activo de la interfaz.
  Locale get locale => _settings.locale;

  /// Carga preferencias desde almacenamiento y notifica oyentes.
  Future<void> load() async {
    await _settings.load();
    notifyListeners();
  }

  /// Cambia el estado de silencio y persiste.
  Future<void> setMuted(bool muted) async {
    await _settings.setMuted(muted);
    notifyListeners();
  }

  /// Cambia el estado de silencio de los efectos de resultado y persiste.
  Future<void> setEffectsMuted(bool muted) async {
    await _settings.setEffectsMuted(muted);
    notifyListeners();
  }

  /// Cambia el idioma y persiste.
  Future<void> setLocale(Locale locale) async {
    await _settings.setLocale(locale);
    notifyListeners();
  }
}
