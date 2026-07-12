import 'package:meta/meta.dart';

/// Tipo de entrada en la galería de coleccionables meta.
enum MetaCollectibleKind {
  /// Desbloqueable en un hito de nivel par (2, 4, …, 20).
  unlockable,

  /// Recompensa exclusiva del último nivel (el más difícil).
  finalLevel,

  /// Placeholder bloqueado sin imagen asignada aún.
  comingSoon,
}

/// Coleccionable meta desbloqueable al completar un hito de progreso.
@immutable
class MetaCollectible {
  /// Crea un coleccionable con [id], [kind] y datos opcionales de hito/imagen.
  const MetaCollectible({
    required this.id,
    required this.kind,
    this.milestoneLevelNumber,
    this.assetPath,
  });

  /// Identificador estable persistido en [PlayerProgress].
  final String id;

  /// Rol del ítem en la galería y las reglas de desbloqueo.
  final MetaCollectibleKind kind;

  /// Nivel de la secuencia que desbloquea este coleccionable (p. ej. 2, 4, 22).
  final int? milestoneLevelNumber;

  /// Ruta del asset en el bundle (`assets/images/collectibles/...`).
  final String? assetPath;

  /// `true` si el ítem puede desbloquearse jugando.
  bool get isUnlockable => kind == MetaCollectibleKind.unlockable || kind == MetaCollectibleKind.finalLevel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetaCollectible &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          milestoneLevelNumber == other.milestoneLevelNumber &&
          assetPath == other.assetPath;

  @override
  int get hashCode => Object.hash(id, kind, milestoneLevelNumber, assetPath);

  @override
  String toString() => 'MetaCollectible($id @ level $milestoneLevelNumber)';
}
