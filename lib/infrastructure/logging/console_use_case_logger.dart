import 'dart:developer' as developer;

import '../../application/ports/i_use_case_logger.dart';

/// Implementación de [IUseCaseLogger] que escribe al log de Dart
/// (`dart:developer`, visible en DevTools/consola de `flutter run`).
class ConsoleUseCaseLogger implements IUseCaseLogger {
  /// Escribe [message] en el log de Dart con nombre `UseCase`.
  @override
  void log(String message) {
    developer.log(message, name: 'UseCase');
  }
}
