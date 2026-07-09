import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import 'app_settings_controller.dart';

/// Pantalla de ajustes: silenciar audio y elegir idioma (es/en).
class SettingsScreen extends StatelessWidget {
  /// Crea la pantalla con el [settingsController] observable.
  const SettingsScreen({super.key, required this.settingsController});

  /// Controlador de preferencias persistidas.
  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListenableBuilder(
        listenable: settingsController,
        builder: (context, _) {
          return ListView(
            children: [
              SwitchListTile(
                key: const ValueKey('settings-mute'),
                title: Text(strings.settingsMute),
                value: settingsController.isMuted,
                onChanged: settingsController.setMuted,
              ),
              ListTile(
                title: Text(strings.settingsLanguage),
              ),
              RadioListTile<Locale>(
                title: Text(strings.settingsLanguageEn),
                value: const Locale('en'),
                groupValue: settingsController.locale,
                onChanged: (locale) {
                  if (locale != null) settingsController.setLocale(locale);
                },
              ),
              RadioListTile<Locale>(
                title: Text(strings.settingsLanguageEs),
                value: const Locale('es'),
                groupValue: settingsController.locale,
                onChanged: (locale) {
                  if (locale != null) settingsController.setLocale(locale);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
