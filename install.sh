#!/usr/bin/env bash
#
# fugue installer — zero-dependency beyond bash + (git or curl/tar).
#
#   curl -fsSL https://raw.githubusercontent.com/smeltery/fugue/main/install.sh | bash
#
# Installs the fugue tree (launcher + profiles + entrypoint) under a share dir
# and symlinks the `fugue` launcher onto your PATH. Override locations with:
#   FUGUE_PREFIX  (default: $HOME/.local)  -> share dir is $FUGUE_PREFIX/share/fugue
#                                             bin link is  $FUGUE_PREFIX/bin/fugue
#   FUGUE_REF     (default: main)          -> branch/tag to install
set -euo pipefail

REPO="https://github.com/smeltery/fugue"
PREFIX="${FUGUE_PREFIX:-$HOME/.local}"
REF="${FUGUE_REF:-main}"
SHARE="$PREFIX/share/fugue"
BINDIR="$PREFIX/bin"

log() { printf 'fugue-install: %s\n' "$*" >&2; }
die() {
  printf 'fugue-install: %s\n' "$*" >&2
  exit 1
}

mkdir -p "$SHARE" "$BINDIR"

if command -v git >/dev/null 2>&1; then
  if [[ -d "$SHARE/.git" ]]; then
    log "updating existing checkout in $SHARE"
    git -C "$SHARE" fetch --depth 1 origin "$REF"
    git -C "$SHARE" checkout -q FETCH_HEAD
  else
    log "cloning $REPO@$REF into $SHARE"
    rm -rf "$SHARE"
    git clone --depth 1 --branch "$REF" "$REPO" "$SHARE"
  fi
elif command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
  log "git not found; downloading tarball of $REF"
  rm -rf "$SHARE"
  mkdir -p "$SHARE"
  curl -fsSL "$REPO/archive/refs/heads/$REF.tar.gz" |
    tar -xz -C "$SHARE" --strip-components=1
else
  die "need either git, or curl + tar, to install"
fi

ln -sf "$SHARE/bin/fugue" "$BINDIR/fugue"
log "installed launcher: $BINDIR/fugue -> $SHARE/bin/fugue"

case ":$PATH:" in
  *":$BINDIR:"*) ;;
  *) log "note: $BINDIR is not on your PATH; add it (e.g. export PATH=\"$BINDIR:\$PATH\")" ;;
esac

log "done. try: fugue --help"
