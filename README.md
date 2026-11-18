# Extra Large Minimap Fix

Fixes the Dota 2 killfeed/combat events HUD when using the extra large minimap.
Console command to get extra large minimap: dota_hud_extra_large_minimap 2
It replaces `panorama/styles/hud/dota_hud_combat_events.vcss_c` inside
`game/dota/pak01_dir.vpk` using [VPKEdit](https://github.com/craftablescience/VPKEdit).

Close Dota 2 before installing. Dota updates may undo the fix, so re-run the installer after patches.

## Windows

Double-click `install_fix.bat`. VPKEdit is installed through winget if it's missing.

## Linux

```bash
./install_fix.sh
```

The script finds Dota 2 through Steam's library folders (native, Flatpak and Snap Steam).
If VPKEdit isn't installed, it offers to download it to `~/.local/share/vpkedit`
(needs `unzip` and `curl` or `wget`). On Arch you can also run `paru -S vpkedit-bin`.

Works on common x86_64 glibc distros (Arch, Ubuntu, Debian, Fedora, SteamOS...).
NixOS and musl-based distros need VPKEdit installed by other means.

## Uninstall

To uninstall just verify integrity of game files.
