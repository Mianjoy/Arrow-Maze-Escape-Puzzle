import '../value_objects/meta_collectible.dart';

/// Catálogo estático de coleccionables meta del juego.
class MetaCollectibleCatalog {
  /// Constructor privado: solo miembros estáticos.
  const MetaCollectibleCatalog._();

  /// Puntos otorgados por cada flecha extraída (debe coincidir con [Game]).
  static const int pointsPerExtractedArrow = 100;

  /// Número del último nivel de la secuencia con coleccionable exclusivo.
  /// Si cambia la cantidad de niveles, actualizar aquí y en el catálogo.
  static const int finalMilestoneLevelNumber = 22;

  static const String _assetBase = 'assets/images/collectibles';

  /// Coleccionables desbloqueables: uno por cada nivel par hasta el penúltimo hito.
  static const List<MetaCollectible> unlockable = [
    MetaCollectible(
      id: 'collectible-milestone-2',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 2,
      assetPath: '$_assetBase/collectible-02.png',
    ),
    MetaCollectible(
      id: 'collectible-milestone-4',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 4,
      assetPath: '$_assetBase/collectible-04.png',
    ),
    MetaCollectible(
      id: 'collectible-milestone-6',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 6,
      assetPath: '$_assetBase/collectible-06.png',
    ),
    MetaCollectible(
      id: 'collectible-milestone-8',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 8,
      assetPath: '$_assetBase/collectible-08.png',
    ),
    MetaCollectible(
      id: 'collectible-milestone-10',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 10,
      assetPath: '$_assetBase/collectible-10.png',
    ),
    MetaCollectible(
      id: 'collectible-milestone-12',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 12,
      assetPath: '$_assetBase/collectible-12.png',
    ),
    MetaCollectible(
      id: 'collectible-milestone-14',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 14,
      assetPath: '$_assetBase/collectible-14.png',
    ),
    MetaCollectible(
      id: 'collectible-milestone-16',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 16,
      assetPath: '$_assetBase/collectible-16.png',
    ),
    MetaCollectible(
      id: 'collectible-milestone-18',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 18,
      assetPath: '$_assetBase/collectible-18.png',
    ),
    MetaCollectible(
      id: 'collectible-milestone-20',
      kind: MetaCollectibleKind.unlockable,
      milestoneLevelNumber: 20,
      assetPath: '$_assetBase/collectible-20.png',
    ),
    MetaCollectible(
      id: 'collectible-final',
      kind: MetaCollectibleKind.finalLevel,
      milestoneLevelNumber: finalMilestoneLevelNumber,
      assetPath: '$_assetBase/collectible-22-final.png',
    ),
  ];

  /// Placeholders siempre bloqueados al final de la galería.
  static const List<MetaCollectible> comingSoon = [
    MetaCollectible(id: 'collectible-coming-soon-1', kind: MetaCollectibleKind.comingSoon),
    MetaCollectible(id: 'collectible-coming-soon-2', kind: MetaCollectibleKind.comingSoon),
    MetaCollectible(id: 'collectible-coming-soon-3', kind: MetaCollectibleKind.comingSoon),
  ];

  /// Todos los ítems desbloqueables (incluye el del último nivel).
  static List<MetaCollectible> get all => unlockable;

  /// Orden de visualización en la galería.
  static List<MetaCollectible> get galleryItems => [...unlockable, ...comingSoon];

  /// Coleccionable exclusivo del último nivel.
  static MetaCollectible get finalCollectible => unlockable.last;

  /// Busca un coleccionable por [id] o devuelve `null`.
  static MetaCollectible? byId(String id) {
    for (final collectible in galleryItems) {
      if (collectible.id == id) return collectible;
    }
    return null;
  }

  /// Coleccionable de hito par asociado a [milestoneLevelNumber], si existe.
  static MetaCollectible? forMilestoneLevel(int milestoneLevelNumber) {
    for (final collectible in unlockable) {
      if (collectible.kind == MetaCollectibleKind.unlockable &&
          collectible.milestoneLevelNumber == milestoneLevelNumber) {
        return collectible;
      }
    }
    return null;
  }

  /// Coleccionable que corresponde al nivel [levelNumber] completado, si aplica.
  static MetaCollectible? forCompletedLevel(int levelNumber) {
    if (levelNumber == finalMilestoneLevelNumber) return finalCollectible;
    return forMilestoneLevel(levelNumber);
  }
}
