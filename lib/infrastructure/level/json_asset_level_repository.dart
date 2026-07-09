import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/domain.dart';

/// Implementación de [ILevelRepository] respaldada por archivos JSON
/// empaquetados como assets de Flutter.
///
/// Flutter no permite listar el contenido de una carpeta de assets en
/// tiempo de ejecución sin un manifiesto explícito, así que esta clase
/// mantiene una lista fija de rutas conocidas. Agregar un nivel nuevo
/// requiere: (1) el archivo en `assets/levels/`, (2) declararlo en
/// `pubspec.yaml` bajo `flutter: assets:`, y (3) agregar su ruta aquí.
/// Una implementación basada en el backend remoto ([RemoteLevelRepository])
/// descubre niveles automáticamente vía `GET /levels`. Esta clase queda como
/// respaldo offline cuando el API no está disponible ([FallbackLevelRepository]).
class JsonAssetLevelRepository implements ILevelRepository {
  /// Crea el repositorio con una [LevelFactory] inyectable (por defecto una
  /// con el calculador de ruta más corta estándar).
  JsonAssetLevelRepository({LevelFactory? levelFactory})
      : _levelFactory = levelFactory ??
            const LevelFactory(
              shortestPathCalculator: ShortestPathCalculator(
                movementEngine: ArrowMovementEngine(
                  collisionValidator: CollisionValidator(),
                ),
              ),
            );

  final LevelFactory _levelFactory;

  static const List<String> _assetPaths = [
    'assets/levels/level_01.json',
    'assets/levels/level_02.json',
    'assets/levels/level_03.json',
  ];

  List<Level>? _cache;

  @override
  Future<List<Level>> findAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final levels = <Level>[];
    for (final path in _assetPaths) {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      levels.add(_levelFactory.fromJson(json));
    }

    _cache = List.unmodifiable(levels);
    return _cache!;
  }

  @override
  Future<Level?> findById(Identifier id) async {
    final levels = await findAll();
    for (final level in levels) {
      if (level.id == id) return level;
    }
    return null;
  }
}
