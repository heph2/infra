---
name: linux-game-compatibility
description: Configure and troubleshoot Windows game releases on NixOS with Wine or Proton, steam-run, Vulkan/DXVK/VKD3D, jc141-style launchers, DwarFS archives, bubblewrap, and gamescope. Use when making an extracted Windows game playable on a NixOS workstation or diagnosing launcher, prefix, graphics, or sandbox failures.
---

# Linux game compatibility

## Scope

Keep changes to launch scripts, prefixes, and user configuration. Do not replace game binaries or add cracks, DRM bypasses, or untrusted downloads. Treat release files as user-supplied and inspect before executing them.

Read the repository's `AGENTS.md` first, then inspect the game directory and any known-good local release under `~/Games`.

## Triage

```sh
find "$GAME" -type f \( -iname '*.exe' -o -iname '*.sh' -o -iname '*.dll' \)
file "$GAME/path/to/game.exe"
command -v wine wineboot wineserver steam-run gamescope bwrap
wine --version
nixos-version
```

Identify the real executable and its required working directory. Unreal Engine builds generally need to start from the directory containing both `Engine/` and the game directory, not from `Binaries/Win64`.

Prefer an existing Proton runner when one is installed. NixOS cannot execute Steam's generic dynamically-linked Proton Wine directly; invoke Proton through `steam-run`:

```sh
PROTON="$HOME/.local/share/Steam/steamapps/common/Proton - Experimental/proton"
COMPAT="$HOME/Games/jc141/compatdata-example"
STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam" \
STEAM_COMPAT_DATA_PATH="$COMPAT" \
STEAM_COMPAT_APP_ID=123456 \
steam-run "$PROTON" run "$GAME/Game/Binaries/Win64/Game.exe" -dx12
```

Give each game a dedicated compat-data directory. Proton owns `$COMPAT/pfx`; do not point `STEAM_COMPAT_DATA_PATH` at the `pfx` subdirectory.

## jc141-style releases

Use the local release's `actions.sh`, `start.*.sh`, `script_default_settings`, and `~/.jc141rc` as the behavioral reference:

- `~/.jc141rc` provides global defaults; the adjacent `script_default_settings` is the per-game override.
- DwarFS releases need `dwarfs`, `fuse-overlayfs`, and `fusermount3`; use `dwarfs-mount` for overlay-backed changes or `dwarfs-extract` when a normal tree is preferable.
- An already-extracted release does not need a fake DwarFS workflow. Launch from the extracted root and keep the prefix outside the game tree.
- Preserve argument forwarding and use arrays for executable arguments.

For a fresh launcher, choose Proton first, then fall back to system Wine only when Proton is unavailable. Set the working directory explicitly, use a unique prefix, and fail with an actionable message when the executable or runner is missing.

## Graphics and sandboxing

- Proton supplies `vkd3d-proton` for DX12 and DXVK for DX9/10/11. Do not force the game's bundled `dxgi.dll` or Microsoft `D3D12Core.dll` ahead of Proton without testing.
- For plain NixOS Wine, Wine's built-in Vulkan-backed D3D12/DXGI may need `WINEDLLOVERRIDES="d3d12,d3d12core=b;dxgi=b"`; use this only for the Wine fallback.
- `steam-run` already creates a bubblewrap environment. Do not nest the launcher's own `bwrap` around `steam-run`; nested user namespaces can fail with `setting up uid map: Read-only file system`.
- Network isolation is optional. Prioritize a working Proton launch over an outer `--unshare-net` sandbox when the FHS wrapper requires its own namespace.
- Gamescope is optional. Disable it while diagnosing invisible or immediately-exiting games. If enabled, set explicit output and game dimensions rather than accepting its 1280x720 fallback.

## Prefix setup and diagnosis

Create the prefix once and let Proton initialize it. First-run Wine messages about `RpcSs`, `winebth`, `winemenubuilder`, OpenXR registry keys, and non-conformant RADV are commonly non-fatal; distinguish them from a missing DLL, loader error, or game process exit.

Use focused diagnostics:

```sh
WINEDEBUG=err+all ./start.e-w.sh 2>&1 | tee /tmp/game-wine.log
ps -eo pid,ppid,stat,etime,args | grep -Ei 'proton|wine|game-name'
find "$COMPAT/pfx/drive_c/users" -type f -mmin -15 -print
```

Check for these failure classes in order:

1. Nix dynamic-loader error → run Proton through `steam-run`.
2. Missing `dxgi.dll`/`d3d12.dll` → stop forcing native DLLs; use Proton/vkd3d or Wine builtins.
3. Nested bwrap uid-map error → skip outer bwrap for Proton.
4. Gamescope starts but the child exits → disable gamescope and test the runner directly.
5. The game process stays alive but no window appears → inspect `DISPLAY`/Wayland setup and test without gamescope before changing graphics variables.

Validate launcher syntax with `bash -n`, verify the runner and executable paths, and perform a bounded smoke launch. Do not claim full playability from a syntax check alone.
