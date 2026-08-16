# Obscura integration roadmap

## Status

Implemented and validated on 2026-08-10. The Freya configuration has not been deployed or switched.

## Decisions

- Target: Freya only.
- Package source: `github:George-Miao/flakes#obscura-browser-bin`, which consumes the official render-enabled Obscura `v0.2.0` release archive.
- Pi integration: direct Chrome DevTools Protocol (CDP) through the existing `agent-browser`-backed `browser` tool.
- Runtime profile: persistent browser state.
- Network exposure: loopback only.
- Puppeteer: do not add it unless direct CDP proves insufficient; `agent-browser` already speaks CDP directly.

## Plan

### 1. Consume the Obscura flake

- Pin `github:George-Miao/flakes` as the `obscura` flake input.
- Use its `obscura-browser-bin` package rather than maintaining a local package.
- Expose that package as `.#obscura` through `dev.nix`.

### 2. Run Obscura on Freya

- Add a Home Manager user service in `hosts/freya/home.nix`.
- Run Obscura approximately as follows:

  ```text
  obscura serve --host 127.0.0.1 --port 9222 --storage-dir ~/.local/state/obscura
  ```

- Restart the service automatically after failures.
- Keep CDP bound to `127.0.0.1`.
- Preserve Obscura's default private-network/SSRF protection.
- Store cookies and local storage under the user's state directory.

### 3. Connect Pi

- Generate `~/.agent-browser/config.json` through Home Manager with:

  ```json
  {
    "cdp": "9222"
  }
  ```

- Reuse Pi's existing `browser` tool; its `agent-browser` process will connect to Obscura over CDP.
- Do not build a custom Pi extension or add `puppeteer-core` unless compatibility testing demonstrates a need.
- Note that this user-level configuration also makes ordinary `agent-browser` CLI commands use Obscura.

### 4. Validation performed

- `nix build .#obscura` succeeded and `obscura --version` reported `0.2.0`.
- A temporary loopback service passed direct fetch, CDP discovery, `agent-browser open`, accessibility snapshot, screenshot capture, and clean-disconnect smoke tests.
- `nixos-rebuild build --impure --flake .#freya` succeeded without switching. `--impure` is required by the pre-existing absolute Emacs config path in `hosts/freya/home.nix`.
- No deployment, switch, service restart, or reboot was performed.

## Known risk

Obscura implements a subset of Chromium's CDP behavior. Core navigation, snapshots, and screenshots passed smoke tests, but advanced `agent-browser` operations may remain incompatible. If direct CDP is insufficient, evaluate a narrowly scoped Puppeteer-based Pi integration rather than adding it preemptively.
