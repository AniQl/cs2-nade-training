# Customization

## Load order

Each map config loads files in this order:

```text
nade_common.cfg      shared practice settings
nade_binds.cfg       default binds and map aliases
nade_<map>.cfg       map-specific overrides and lineup binds
nade_user.cfg        personal overrides (loaded last)
```

Because `nade_user.cfg` is loaded last, it wins over the defaults and the map file.

## Where to make changes

| Goal | File |
|---|---|
| Change your own keys, settings, or lineups | `nade_user.cfg` |
| Change defaults for everyone using the repo | `nade_binds.cfg` or `nade_common.cfg` |
| Change one map only | `nade_<map>.cfg` |
| Add a new map | Copy an existing map config and update the alias/help/docs |

After installation, these files are in:

```text
<CS2 install>/game/csgo/cfg/
```

After editing a config, run the matching command in the console:

```cfg
exec nade_mirage
```

## Personal overrides

`cfg/nade_user.cfg` is the recommended place for personal changes. The installers preserve it when updating.

Edit the installed copy at `<CS2 install>/game/csgo/cfg/nade_user.cfg`. The file inside the repository is only the template copied by the installer.

Example: rebind rethrow to a different key.

```cfg
unbind "MOUSE4"
bind "MOUSE5" "sv_rethrow_last_grenade"
```

Example: disable bullet impacts but keep trajectory preview.

```cfg
sv_showimpacts 0
```

Example: shorter practice rounds.

```cfg
mp_roundtime 30
mp_roundtime_defuse 30
```

## Changing default binds

Edit `cfg/nade_binds.cfg`:

```cfg
bind "MOUSE4" "sv_rethrow_last_grenade"
bind "MOUSE5" "give weapon_flashbang; give weapon_hegrenade; give weapon_smokegrenade; give weapon_molotov; give weapon_incgrenade; give weapon_decoy; give item_assaultsuit"
bind "DEL" "cl_removedecals; ent_fire smokegrenade_projectile kill; ent_fire inferno kill; ent_fire molotov_groundfire kill; ent_fire molotov_projectile kill; ent_fire flashbang_projectile kill; ent_fire hegrenade_projectile kill"
bind "PGUP" "cl_sim_grenade_trajectory 1; sv_grenade_trajectory_prac_pipreview 1; sv_grenade_trajectory_prac_trailtime 8"
bind "PGDN" "cl_sim_grenade_trajectory 0; sv_grenade_trajectory_prac_pipreview 0; sv_grenade_trajectory_prac_trailtime 0"
bind "INS" "mp_restartgame 1"
bind "HOME" "toggle sv_showimpacts 0 1"
bind "END" "toggle cl_showpos 0 1"
bind "F9" "exec nade"
```

If you change a key that `nade_off.cfg` unbinds, update `nade_off.cfg` to match.

## Adding a map

1. Copy a map config:

```bash
cp cfg/nade_mirage.cfg cfg/nade_my_map.cfg
```

2. Edit the new file and change the header/echo text to your map name.

3. Add an alias in `cfg/nade_binds.cfg`:

```cfg
alias nade_my_map "exec nade_my_map"
```

4. Add the command to `cfg/nade_help.cfg` and the README command list.

5. Install again and run:

```cfg
exec nade_my_map
```

The map file name must start with `nade_` and end with `.cfg`.

## Adding lineup positions

1. Load the map and run `exec nade_<map>`.
2. Stand at the lineup position and look in the throw direction.
3. Run `getpos`. CS2 prints a `setpos` and `setang` pair.
4. Add the position to the matching map file or to `nade_user.cfg`:

```cfg
bind "F1" "setpos 1234.5 678.9 -123.4; setang 0.0 90.0 0.0"
```

5. Reload the config:

```cfg
exec nade_mirage
```

Use keys that you do not need during practice. `F1`, `F2`, `F8`, `J`, `K`, `L`, `N`, `O`, and `P` are free by default, but check your own bindings with `key_listboundkeys` first.

### Stale lineup binds

If you add lineup keys to several maps, use the same keys in each map file and reassign or unbind them in every file. Otherwise, a bind from the previous map can remain active after a map change.

Example cleanup at the top of a map file:

```cfg
unbind "F1"
unbind "F2"
```

## Changing shared practice settings

Edit `cfg/nade_common.cfg`. It contains the shared cvars for round time, money, respawn, utility, trajectory, impacts, and bots.

If you only want a personal change, put the same cvar in `nade_user.cfg` instead.

## Updating

1. Pull the latest changes.
2. Run the installer again.
3. Your `nade_user.cfg` is preserved unless you pass the force option.
4. Existing installed configs are backed up to a `nade_backup_<timestamp>` folder inside the cfg directory.

## Testing changes

1. Load a local practice map.
2. Run `exec nade_<map>`.
3. Check the console for unknown-command errors.
4. Test each changed bind.
5. Run `exec nade_off` and confirm the built-in training binds are removed and `DEL` is restored.

`nade_off.cfg` does not know about personal binds added in `nade_user.cfg`. Unbind those yourself before disabling or uninstalling.
