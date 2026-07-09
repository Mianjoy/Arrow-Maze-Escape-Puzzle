import 'package:flutter/material.dart';

import '../../application/ports/i_app_settings.dart';

/// Preferencias en memoria para tests y E2E sin disco.
class InMemoryAppSettings implements IAppSettings {
  bool _muted = false;
  Locale _locale = const Locale('en');

  @override
  bool get isMuted => _muted;

  @override
  Locale get locale => _locale;

  @override
  Future<void> load() async {}

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
  }

  @override
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
  }
}
