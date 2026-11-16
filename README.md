# CS2 Nade Training

One-command grenade training setup for Counter-Strike 2 on Windows and Linux.

Load a practice map, run `exec nade_mirage` (or the command for your map), and get the full practice environment, utility binds, and map shortcuts immediately.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Windows](https://img.shields.io/badge/platform-Windows-0078D6)
![Linux](https://img.shields.io/badge/platform-Linux-FCC624)

## Features

- One command per Active Duty map.
- No numpad required.
- Shared practice cvars: cheats, infinite utility, free buying, extended rounds, instant respawn, trajectory preview, bullet impacts, and bots removed.
- Grenade binds for rethrow, full utility, clearing smokes/fire/decals, trajectory toggles, round restart, impacts, and position display.
- Position display is off by default and can be toggled with `END`.
- Personal overrides live in a separate `nade_user.cfg` file that installers preserve on update.
- Windows and Linux installers with Steam library auto-detection.
- Uninstallers that preserve your personal config by default.
- Full documentation for customization, lineups, and troubleshooting.

## Requirements

- Counter-Strike 2 with the developer console enabled.
- A local/listen practice server. Use `Play` -> `Practice`, or load a map from the console.
- Windows 10/11 with PowerShell 5.1, or Linux with Bash.
- Git is optional if you download the repository ZIP instead.

The configs use `sv_cheats` and server cvars. They are intended for local or private practice only and do not work in official matchmaking.

## Installation

### Windows

```powershell
git clone https://github.com/AniQl/cs2-nade-training.git
cd cs2-nade-training
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The installer auto-detects Steam and CS2. If detection fails, pass the cfg folder explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Cs2Cfg "D:\SteamLibrary\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"
```

Useful options:

| Option | Description |
|---|---|
| `-Cs2Cfg <path>` | Explicit CS2 install root, `game\csgo` folder, or cfg folder. |
| `-Force` | Overwrite an existing `nade_user.cfg`. |
| `-NoBackup` | Do not back up existing `nade_*.cfg` files. |
| `-DryRun` | Show what would happen without changing files. |

### Linux

```bash
git clone https://github.com/AniQl/cs2-nade-training.git
cd cs2-nade-training
bash ./install.sh
```

The installer auto-detects standard Steam libraries and Flatpak Steam. If detection fails:

```bash
bash ./install.sh --cfg-dir "$HOME/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg"
```

Useful options:

| Option | Description |
|---|---|
| `--cfg-dir <path>` | Explicit CS2 install root, `game/csgo` folder, or cfg folder. |
| `--force` | Overwrite an existing `nade_user.cfg`. |
| `--no-backup` | Do not back up existing `nade_*.cfg` files. |
| `--dry-run` | Show what would happen without changing files. |

### Manual installation

Copy everything from `cfg/` into your CS2 config folder:

```text
<CS2 install>/game/csgo/cfg/
```

On Steam the CS2 folder is usually named `Counter-Strike Global Offensive`.

## Usage

1. Start CS2 and load a practice map.
2. Open the developer console with `~`.
3. Run the matching map command.

| Map | Command |
|---|---|
| Ancient | `exec nade_ancient` |
| Anubis | `exec nade_anubis` |
| Cache | `exec nade_cache` |
| Dust II | `exec nade_dust2` |
| Inferno | `exec nade_inferno` |
| Mirage | `exec nade_mirage` |
| Nuke | `exec nade_nuke` |

Generic setup for the current map:

```cfg
exec nade
```

After loading a config, these shortcuts are also available:

```cfg
nade_ancient
nade_anubis
nade_cache
nade_dust2
nade_inferno
nade_mirage
nade_nuke
nade_help
nade_off
```

Map shortcuts assume you are already on that map. After a map change, run `exec nade_<map>` again.

## Binds

| Key | Action |
|---|---|
| `MOUSE4` | Rethrow the last grenade. |
| `MOUSE5` | Give flashbang, HE, smoke, molotov, incendiary, decoy, and armor. |
| `DEL` | Clear smoke, molotov/incendiary fire, utility projectiles, and decals. |
| `PGUP` | Turn grenade trajectory and landing preview on. |
| `PGDN` | Turn grenade trajectory and landing preview off. |
| `INS` | Restart the round. |
| `HOME` | Toggle bullet impacts. |
| `END` | Toggle position and angle display. Off by default. |
| `F9` | Reload the complete setup with `exec nade`. |

`DEL` is bound to `sellbackall` by default in CS2. The training config overrides it; `exec nade_off` restores it.

The `ALT` and `CAPSLOCK` noclip binds are not modified.

## Customization

The main customization file is `nade_user.cfg`. It is loaded last, so anything in it overrides the defaults and map files.

After installation, edit the copy at `<CS2 install>/game/csgo/cfg/nade_user.cfg`. The `cfg/nade_user.cfg` file in this repository is only the template used by the installer.

Examples:

```cfg
// Add a lineup position
bind "F1" "setpos 1234.5 678.9 -123.4; setang 0.0 90.0 0.0"

// Disable bullet impacts
sv_showimpacts 0

// Keep rounds shorter
mp_roundtime 30
```

Installers preserve an existing `nade_user.cfg` by default. See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for the full guide, including adding maps and lineup positions.

## Updating

```bash
git pull
```

Then run the installer again. Existing `nade_user.cfg` content is preserved, and the previous installed configs are backed up before being replaced.

## Uninstalling

Run this in CS2 first so the built-in training binds are cleared:

```cfg
exec nade_off
```

If you added your own binds in `nade_user.cfg`, unbind those manually as well; `nade_off` does not know about personal binds.

Then run the uninstaller:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

```bash
bash ./uninstall.sh
```

The uninstaller removes the managed configs, preserves `nade_user.cfg` by default, and backs up files before removal. Use `-RemoveUserConfig` or `--remove-user-config` to remove your personal config too.

## Important limitations

- Practice commands require `sv_cheats 1`. Use a local/listen practice server, not official matchmaking.
- On a remote server, server-only commands such as `mp_*`, `give`, and `ent_fire` require server console or rcon access.
- Chat commands such as `!help` cannot be implemented with client-side `.cfg` files. They require a server-side plugin such as SourceMod or CounterStrikeSharp.
- Valve can rename or remove cvars. Shared settings are centralized in `cfg/nade_common.cfg` for easier updates.

More help: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## Repository layout

```text
cs2-nade-training/
├── cfg/                  # Files copied into game/csgo/cfg
├── docs/                 # Customization and troubleshooting guides
├── install.ps1           # Windows installer
├── uninstall.ps1         # Windows uninstaller
├── install.sh            # Linux installer
├── uninstall.sh          # Linux uninstaller
├── README.md
└── LICENSE
```

## Contributing

Issues and pull requests are welcome. Test config changes on a local practice server before submitting them, and keep personal key choices in `nade_user.cfg` rather than the shared defaults.

## License

MIT. See [LICENSE](LICENSE).
