#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SOURCE_DIR="$SCRIPT_DIR/cfg"
CFG_DIR=""
FORCE=0
NO_BACKUP=0
DRY_RUN=0

usage() {
    cat <<'EOF'
CS2 Nade Training installer (Linux)

Usage:
  bash install.sh [options]

Options:
  --cfg-dir PATH   Explicit CS2 cfg directory, game/csgo directory, or CS2 root
  --force          Overwrite an existing nade_user.cfg
  --no-backup      Do not back up existing nade_*.cfg files
  --dry-run        Show actions without copying files
  -h, --help       Show this help
EOF
}

log() { printf '[nade] %s\n' "$*"; }
warn() { printf '[nade] WARNING: %s\n' "$*" >&2; }
die() { printf '[nade] ERROR: %s\n' "$*" >&2; exit 1; }

while [ "$#" -gt 0 ]; do
    case "$1" in
        --cfg-dir)
            [ "$#" -ge 2 ] || die "--cfg-dir requires a path"
            CFG_DIR="$2"
            shift 2
            ;;
        --cfg-dir=*)
            CFG_DIR="${1#*=}"
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --no-backup)
            NO_BACKUP=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1 (use --help)"
            ;;
    esac
done

[ -d "$SOURCE_DIR" ] || die "Config folder not found: $SOURCE_DIR"

resolve_cfg_dir() {
    local path="$1" candidate

    [ -e "$path" ] || die "Path does not exist: $path"
    [ -d "$path" ] || die "Path is not a directory: $path"

    for candidate in "$path" "$path/game/csgo/cfg" "$path/csgo/cfg" "$path/cfg"; do
        if [ -d "$candidate" ] && [ "$(basename "$candidate")" = "cfg" ]; then
            (cd -- "$candidate" && pwd -P)
            return 0
        fi
    done

    die "Could not find a csgo cfg directory under: $path"
}

parse_library_paths() {
    local vdf="$1"
    [ -f "$vdf" ] || return 0
    sed -n 's/.*"path"[[:space:]]*"\([^"]*\)".*/\1/p' "$vdf"
}

find_cs2_cfg_dir() {
    local roots=() libs=() root vdf lib folder candidate
    local -A seen_libs=()

    roots+=(
        "$HOME/.steam/steam"
        "$HOME/.local/share/Steam"
        "$HOME/.steam/root"
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
    )

    for root in "${roots[@]}"; do
        [ -d "$root" ] || continue
        libs+=("$root")
        for vdf in "$root/steamapps/libraryfolders.vdf" "$root/config/libraryfolders.vdf"; do
            while IFS= read -r lib; do
                [ -n "$lib" ] && libs+=("$lib")
            done < <(parse_library_paths "$vdf")
        done
    done

    for lib in "${libs[@]}"; do
        if [ -n "${seen_libs[$lib]:-}" ]; then
            continue
        fi
        seen_libs["$lib"]=1

        for folder in "Counter-Strike Global Offensive" "Counter-Strike 2"; do
            candidate="$lib/steamapps/common/$folder/game/csgo/cfg"
            if [ -d "$candidate" ]; then
                (cd -- "$candidate" && pwd -P)
                return 0
            fi
        done
    done

    return 1
}

if [ -z "$CFG_DIR" ]; then
    CFG_DIR="$(find_cs2_cfg_dir)" || die "Could not locate CS2. Use --cfg-dir /path/to/game/csgo/cfg."
else
    CFG_DIR="$(resolve_cfg_dir "$CFG_DIR")"
fi

shopt -s nullglob
source_files=("$SOURCE_DIR"/*.cfg)
shopt -u nullglob

[ "${#source_files[@]}" -gt 0 ] || die "No .cfg files found in: $SOURCE_DIR"

log "Source: $SOURCE_DIR"
log "Target: $CFG_DIR"

if [ "$NO_BACKUP" -eq 0 ]; then
    shopt -s nullglob
    existing=("$CFG_DIR"/nade_*.cfg)
    shopt -u nullglob

    if [ "${#existing[@]}" -gt 0 ]; then
        backup_dir="$CFG_DIR/nade_backup_$(date +%Y%m%d-%H%M%S)_$$"
        if [ "$DRY_RUN" -eq 1 ]; then
            log "Would back up existing configs to: $backup_dir"
        else
            mkdir -p "$backup_dir"
            cp -p "${existing[@]}" "$backup_dir"/
            log "Backed up existing configs to: $backup_dir"
        fi
    fi
fi

copied=0
for src in "${source_files[@]}"; do
    name="$(basename "$src")"

    if [ "$name" = "nade_user.cfg" ] && [ -f "$CFG_DIR/$name" ] && [ "$FORCE" -eq 0 ]; then
        warn "Preserving existing nade_user.cfg (use --force to overwrite)"
        continue
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        log "Would install: $name"
    else
        cp -f "$src" "$CFG_DIR/$name"
        log "Installed: $name"
    fi
    copied=$((copied + 1))
done

echo
if [ "$DRY_RUN" -eq 1 ]; then
    log "Dry run complete. No files were changed."
else
    log "Installed $copied file(s) to: $CFG_DIR"
fi
echo
echo "Next:"
echo "  1. Start CS2 and load a practice map."
echo "  2. Open the console and run: exec nade_mirage"
echo "  3. Run exec nade_help for the full command list."
