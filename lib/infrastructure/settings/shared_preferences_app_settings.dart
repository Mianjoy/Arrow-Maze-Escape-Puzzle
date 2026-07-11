import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/ports/i_app_settings.dart';

/// Preferencias de app (idioma y mute) en [SharedPreferences].
class SharedPreferencesAppSettings implements IAppSettings {
  /// Crea el servicio de preferencias respaldado por [_prefs].
  SharedPreferencesAppSettings(this._prefs);

  final SharedPreferences _prefs;

  static const _mutedKey = 'settings_muted';
  static const _effectsMutedKey = 'settings_effects_muted';
  static const _localeKey = 'settings_locale';

  bool _muted = false;
  bool _effectsMuted = false;
  Locale _locale = const Locale('en');

  /// Crea la instancia tras inicializar preferencias.
  static Future<SharedPreferencesAppSettings> create() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SharedPreferencesAppSettings(prefs);
    await settings.load();
    return settings;
  }

  /// Indica si el audio está silenciado.
  @override
  bool get isMuted => _muted;

  /// Indica si los efectos de victoria, derrota y flecha extraída están silenciados.
  @override
  bool get isEffectsMuted => _effectsMuted;

  /// Idioma activo de la interfaz.
  @override
  Locale get locale => _locale;

  @override
  /// Lee mute e idioma desde almacenamiento local.
  Future<void> load() async {
    _muted = _prefs.getBool(_mutedKey) ?? false;
    _effectsMuted = _prefs.getBool(_effectsMutedKey) ?? false;
    final code = _prefs.getString(_localeKey) ?? 'en';
    _locale = Locale(code);
  }

  @override
  /// Persiste el estado de silencio.
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    await _prefs.setBool(_mutedKey, muted);
  }

  @override
  /// Persiste el estado de silencio de los efectos de resultado de partida.
  Future<void> setEffectsMuted(bool muted) async {
    _effectsMuted = muted;
    await _prefs.setBool(_effectsMutedKey, muted);
  }

  @override
  /// Persiste el código de idioma (`en` / `es`).
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs.setString(_localeKey, locale.languageCode);
  }
}
