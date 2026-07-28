#!/bin/sh
set -eu

FLAKE_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
NIX_EXTRA="--extra-experimental-features"
NIX_FEATURES="nix-command flakes"
AGE_DEST="$HOME/.config/sops/age/keys.txt"
DARWIN_REF="github:nix-darwin/nix-darwin/master#darwin-rebuild"
HM_REF="github:nix-community/home-manager#home-manager"

HOST=""
AGE_KEY=""
DRY_RUN=0
FORCE_KEY=0

log() { printf '\033[1;34m::\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1" >&2; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$1" >&2; exit 1; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '   + %s\n' "$*"
  else
    "$@"
  fi
}

usage() {
  cat <<EOF
Usage: ./bootstrap.sh [options]

Converges the current machine onto its flake config (NixOS, nix-darwin or
standalone home-manager). Does not partition disks or install bare-metal.

Options:
  --host <name>      Config to build. Defaults to the machine hostname, or to
                     the only config of the detected class when unambiguous.
  --age-key <path>   sops age key to install at $AGE_DEST (0600) before switch.
  --force-key        Overwrite an existing age key at the destination.
  -n, --dry-run      Print the steps without running them.
  -h, --help         Show this help.

Detected classes:
  Darwin              -> darwinConfigurations  (massan)
  Linux + ID=nixos    -> nixosConfigurations   (felix, golf, tortinha, wsl)
  Linux (other)       -> homeConfigurations    (home-linux)
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST="${2:?--host needs a value}"; shift 2 ;;
    --host=*) HOST="${1#*=}"; shift ;;
    --age-key) AGE_KEY="${2:?--age-key needs a value}"; shift 2 ;;
    --age-key=*) AGE_KEY="${1#*=}"; shift ;;
    --force-key) FORCE_KEY=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
done

detect_class() {
  case "$(uname -s)" in
    Darwin) printf darwin ;;
    Linux)
      if [ -e /etc/os-release ] && grep -q '^ID=nixos' /etc/os-release; then
        printf nixos
      else
        printf home
      fi ;;
    *) die "unsupported OS: $(uname -s)" ;;
  esac
}

subdir_for() {
  case "$1" in
    darwin) printf darwin ;;
    nixos) printf nixos ;;
    home) printf home-manager ;;
  esac
}

list_hosts() {
  sub=$(subdir_for "$1")
  for d in "$FLAKE_DIR/hosts/$sub"/*/; do
    [ -d "$d" ] && basename "$d"
  done
}

resolve_host() {
  class=$1
  avail=$(list_hosts "$class")
  [ -n "$avail" ] || die "no hosts under hosts/$(subdir_for "$class")"
  cand=$HOST
  [ -n "$cand" ] || cand=$(uname -n | cut -d. -f1)
  for h in $avail; do
    [ "$h" = "$cand" ] && { printf '%s' "$h"; return 0; }
  done
  count=$(list_hosts "$class" | wc -l | tr -d ' ')
  if [ "$count" = 1 ]; then
    printf '%s' "$avail"
    return 0
  fi
  die "host '$cand' not valid for $class; available: $(echo "$avail" | tr '\n' ' ')(use --host)"
}

ensure_nix() {
  if command -v nix >/dev/null 2>&1; then return 0; fi
  [ "$CLASS" != nixos ] || die "nix not on PATH on a NixOS system; aborting"
  command -v curl >/dev/null 2>&1 || die "curl is required to install Nix"
  log "Nix not found; installing upstream Nix (multi-user daemon)"
  run sh -c 'curl --proto =https --tlsv1.2 -sSf -L https://nixos.org/nix/install | sh -s -- --daemon'
  profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  [ -e "$profile" ] && . "$profile"
  command -v nix >/dev/null 2>&1 || die "Nix installed but not on PATH; open a new shell and re-run"
}

provision_age_key() {
  dir=$(dirname "$AGE_DEST")
  if [ -n "$AGE_KEY" ]; then
    [ -f "$AGE_KEY" ] || die "age key file not found: $AGE_KEY"
    if [ -f "$AGE_DEST" ] && [ "$FORCE_KEY" -eq 0 ]; then
      warn "age key already present at $AGE_DEST; keeping it (--force-key to overwrite)"
    else
      log "installing age key -> $AGE_DEST"
      run mkdir -p "$dir"
      run chmod 700 "$dir"
      run cp "$AGE_KEY" "$AGE_DEST"
      run chmod 600 "$AGE_DEST"
    fi
  fi
  if [ ! -f "$AGE_DEST" ] && [ "$DRY_RUN" -eq 0 ]; then
    die "no age key at $AGE_DEST and no --age-key given; sops secrets would fail on activation"
  fi
}

rebuild() {
  target="$FLAKE_DIR#$HOST"
  case "$CLASS" in
    darwin)
      if command -v darwin-rebuild >/dev/null 2>&1; then
        run sudo darwin-rebuild switch --flake "$target"
      else
        log "first darwin activation (via nix run $DARWIN_REF)"
        run sudo nix "$NIX_EXTRA" "$NIX_FEATURES" run "$DARWIN_REF" -- switch --flake "$target"
      fi ;;
    nixos)
      run sudo nixos-rebuild switch --flake "$target" ;;
    home)
      if command -v home-manager >/dev/null 2>&1; then
        run home-manager switch -b backup --flake "$target"
      else
        run nix "$NIX_EXTRA" "$NIX_FEATURES" run "$HM_REF" -- switch -b backup --flake "$target"
      fi ;;
  esac
}

CLASS=$(detect_class)
HOST=$(resolve_host "$CLASS")

log "flake:  $FLAKE_DIR"
log "class:  $CLASS"
log "host:   $HOST"
log "agekey: $AGE_DEST"
[ "$DRY_RUN" -eq 1 ] && warn "dry-run: no changes will be made"

ensure_nix
provision_age_key
rebuild

log "done: $HOST converged"
