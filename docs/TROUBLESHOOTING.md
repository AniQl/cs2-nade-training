# Troubleshooting

## The installer cannot find CS2

Pass the cfg folder explicitly.

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Cs2Cfg "D:\SteamLibrary\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"
```

Linux:

```bash
bash ./install.sh --cfg-dir "$HOME/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg"
```

The CS2 install folder is usually named `Counter-Strike Global Offensive`, even in CS2.

Common Linux locations:

```text
~/.steam/steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg
~/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg
~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg
```

## PowerShell blocks the script

Run it with a process-scoped execution policy bypass:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

No permanent execution-policy change is needed.

## `exec` cannot find the file

- The `.cfg` files must be directly inside `game/csgo/cfg`.
- Use the file name without `.cfg`: `exec nade_mirage`, not `exec nade_mirage.cfg`.
- Make sure the file did not become `nade_mirage.cfg.txt`.

## Commands do nothing

- Run the configs on a local/listen practice server, not in official matchmaking.
- Make sure `sv_cheats 1` succeeded.
- On a remote server, commands such as `mp_*`, `give`, `ent_fire`, and `sv_cheats` require server console or rcon access.
- Run `exec nade_<map>` again after a map change.

## Binds stop working after a map change or restart

Re-run the map config:

```cfg
exec nade_mirage
```

Map shortcuts such as `nade_mirage` are convenience aliases. Use `exec nade_<map>` after a map change.

## `DEL` no longer sells items

Expected. The training config overrides the default `sellbackall` bind. Run:

```cfg
exec nade_off
```

This restores `DEL` to `sellbackall`, unbinds the custom keys, and disables the visual helpers.

## Position/angle display is not visible

It is off by default. Press `END` to toggle it on, or run:

```cfg
cl_showpos 1
```

## My `nade_user.cfg` changes are not applied

- Make sure `nade_user.cfg` exists in `game/csgo/cfg`.
- Run the map config again after editing it.
- Check the console for `[nade] user overrides loaded.`
- If you reinstall, do not use `-Force` / `--force` unless you intend to overwrite it.

## Chat commands such as `!help` do not work

Vanilla CS2 client configs cannot intercept chat messages. Chat triggers require a server-side plugin such as SourceMod or CounterStrikeSharp on a server you control. The available commands in this project are console commands and key binds.

## `sv_grenade_trajectory` or other CS:GO commands do nothing

Those old CS:GO cvars no longer exist in CS2. This project uses the current CS2 names:

```cfg
sv_grenade_trajectory_prac_pipreview
sv_grenade_trajectory_prac_trailtime
cl_sim_grenade_trajectory
cl_removedecals
```

## A cvar or command stopped working after a CS2 update

Valve occasionally renames or removes commands. Open an issue with:

- the CS2 build/date
- the command that fails
- the console error, if any

## Uninstalling

Run this in CS2 first:

```cfg
exec nade_off
```

If you added personal binds in `nade_user.cfg`, unbind those manually too. Then run the uninstaller and pass the cfg path if auto-detection fails:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -Cs2Cfg "D:\path\to\game\csgo\cfg"
```

```bash
bash ./uninstall.sh --cfg-dir "/path/to/game/csgo/cfg"
```

By default `nade_user.cfg` is preserved. Use `-RemoveUserConfig` or `--remove-user-config` to remove it too.
