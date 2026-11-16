#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CFG_DIR=""
REMOVE_USER=0
NO_BACKUP=0
DRY_RUN=0

usage() {
    cat <<'EOF'
CS2 Nade Training uninstaller (Linux)

Usage:
  bash uninstall.sh [options]

Options:
  --cfg-dir PATH          Explicit CS2 cfg directory, game/csgo directory, or CS2 root
  --remove-user-config    Also remove nade_user.cfg
  --no-backup             Do not back up files before removing them
  --dry-run               Show actions without changing files
  -h, --help              Show this help
EOF
}

log() { printf '[nade] %s\n' "$*"; }
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
        --remove-user-config)
            REMOVE_USER=1
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

managed_files=(
    "nade.cfg"
    "nade_common.cfg"
    "nade_binds.cfg"
    "nade_user.cfg"
    "nade_help.cfg"
    "nade_off.cfg"
    "nade_ancient.cfg"
    "nade_anubis.cfg"
    "nade_cache.cfg"
    "nade_dust2.cfg"
    "nade_inferno.cfg"
    "nade_mirage.cfg"
    "nade_nuke.cfg"
)

log "Target: $CFG_DIR"
echo "Run 'exec nade_off' in CS2 before uninstalling to clear the binds."
echo

existing=()
for name in "${managed_files[@]}"; do
    path="$CFG_DIR/$name"
    [ -f "$path" ] || continue

    if [ "$name" = "nade_user.cfg" ] && [ "$REMOVE_USER" -eq 0 ]; then
        log "Preserving: $name (use --remove-user-config to remove it)"
        continue
    fi

    existing+=("$path")
done

if [ "${#existing[@]}" -eq 0 ]; then
    log "No managed files found."
    exit 0
fi

if [ "$NO_BACKUP" -eq 0 ]; then
    backup_dir="$CFG_DIR/nade_backup_$(date +%Y%m%d-%H%M%S)_$$"
    if [ "$DRY_RUN" -eq 1 ]; then
        log "Would back up files to: $backup_dir"
    else
        mkdir -p "$backup_dir"
        cp -p "${existing[@]}" "$backup_dir"/
        log "Backed up files to: $backup_dir"
    fi
fi

for path in "${existing[@]}"; do
    if [ "$DRY_RUN" -eq 1 ]; then
        log "Would remove: $(basename "$path")"
    else
        rm -f "$path"
        log "Removed: $(basename "$path")"
    fi
done

echo
if [ "$DRY_RUN" -eq 1 ]; then
    log "Dry run complete. No files were changed."
else
    log "Uninstall complete."
fi
