import 'package:flutter/material.dart';

import '../../application/ports/i_app_settings.dart';

/// Preferencias en memoria para tests y E2E sin disco.
class InMemoryAppSettings implements IAppSettings {
  bool _muted = false;
  bool _effectsMuted = false;
  Locale _locale = const Locale('en');

  /// Indica si el audio está silenciado.
  @override
  bool get isMuted => _muted;

  /// Indica si los efectos de victoria, derrota y flecha extraída están silenciados.
  @override
  bool get isEffectsMuted => _effectsMuted;

  /// Idioma activo de la interfaz.
  @override
  Locale get locale => _locale;

  /// No realiza carga desde disco (valores por defecto en memoria).
  @override
  Future<void> load() async {}

  /// Actualiza el estado de silencio en memoria.
  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
  }

  /// Actualiza el estado de silencio de efectos en memoria.
  @override
  Future<void> setEffectsMuted(bool muted) async {
    _effectsMuted = muted;
  }

  /// Actualiza el idioma activo en memoria.
  @override
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
  }
}
