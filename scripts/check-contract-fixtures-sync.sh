#!/usr/bin/env bash
#
# Compara, por hash SHA-256, los fixtures de docs/contract/fixtures/ de este
# repo contra su copia en el repo backend (BackEnd-ArrowMaze), para detectar
# si un lado editó un fixture de contrato sin replicar el cambio en el otro
# (ver docs/contract/fixtures/README.md).
#
# Uso:
#   scripts/check-contract-fixtures-sync.sh [ruta-al-repo-backend]
#
# Sin argumento, intenta en este orden:
#   1. Un checkout hermano local ../BackEnd-ArrowMaze (uso en desarrollo,
#      donde ambos repos ya están clonados uno junto al otro).
#   2. Clonar el repo remoto (uso en CI). Si el repo es privado o no hay
#      acceso de red, el script lo reporta y TERMINA SIN FALLAR el build —
#      esta verificación es una red de seguridad adicional, no un gate que
#      deba poder tumbar el pipeline por un problema de acceso ajeno a los
#      fixtures en sí.
#
# Si SÍ logra comparar y encuentra una divergencia real, falla (exit 1).

set -euo pipefail

THIS_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES_REL_DIR="docs/contract/fixtures"

OTHER_REPO_URL="https://github.com/Georopeza/BackEnd-ArrowMaze.git"
OTHER_REPO_SIBLING="$THIS_REPO_ROOT/../BackEnd-ArrowMaze"
OTHER_REPO_REF="${CONTRACT_FIXTURES_OTHER_REPO_REF:-develop}"

OTHER_REPO_PATH="${1:-}"
CLEANUP_TMPDIR=""

cleanup() {
  if [ -n "$CLEANUP_TMPDIR" ] && [ -d "$CLEANUP_TMPDIR" ]; then
    rm -rf "$CLEANUP_TMPDIR"
  fi
}
trap cleanup EXIT

if [ -z "$OTHER_REPO_PATH" ]; then
  if [ -d "$OTHER_REPO_SIBLING/$FIXTURES_REL_DIR" ]; then
    OTHER_REPO_PATH="$OTHER_REPO_SIBLING"
    echo "Usando checkout hermano local: $OTHER_REPO_PATH"
  else
    CLEANUP_TMPDIR="$(mktemp -d)"
    OTHER_REPO_PATH="$CLEANUP_TMPDIR/other-repo"
    echo "No hay checkout hermano local; clonando $OTHER_REPO_URL (rama $OTHER_REPO_REF)..."
    if ! git clone --depth 1 --branch "$OTHER_REPO_REF" "$OTHER_REPO_URL" "$OTHER_REPO_PATH" 2>/tmp/clone-error.log; then
      echo "No se pudo clonar el repo backend (privado o sin acceso de red)."
      echo "Omitiendo verificación de sincronización de fixtures (no es un fallo)."
      cat /tmp/clone-error.log 2>/dev/null || true
      exit 0
    fi
  fi
fi

if [ ! -d "$OTHER_REPO_PATH/$FIXTURES_REL_DIR" ]; then
  echo "El repo backend en '$OTHER_REPO_PATH' no tiene '$FIXTURES_REL_DIR'; omitiendo (no es un fallo)."
  exit 0
fi

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

mismatch=0

shopt -s nullglob
for file in "$THIS_REPO_ROOT/$FIXTURES_REL_DIR"/*.json; do
  name="$(basename "$file")"
  other_file="$OTHER_REPO_PATH/$FIXTURES_REL_DIR/$name"

  if [ ! -f "$other_file" ]; then
    echo "FALTA en el repo backend: $FIXTURES_REL_DIR/$name"
    mismatch=1
    continue
  fi

  this_hash="$(hash_file "$file")"
  other_hash="$(hash_file "$other_file")"

  if [ "$this_hash" != "$other_hash" ]; then
    echo "DIVERGENTE: $FIXTURES_REL_DIR/$name"
    echo "  este repo:    $this_hash"
    echo "  repo backend: $other_hash"
    mismatch=1
  else
    echo "OK: $FIXTURES_REL_DIR/$name"
  fi
done

if [ "$mismatch" -ne 0 ]; then
  echo ""
  echo "Uno o más fixtures de contrato divergieron entre frontend y backend."
  exit 1
fi

echo ""
echo "Todos los fixtures de contrato coinciden entre frontend y backend."
