# Infrastructure Repository

Personal NixOS/nix-darwin infrastructure managing 11 machines across desktops, laptops, servers, VPS, NAS, WSL, phone, and router.

## Architecture: Dendritic Pattern

This repo uses the **Dendritic Pattern** — configuration organized by feature/aspect, not by host.

### Key concepts

- Every `.nix` file under `modules/` is a **flake-parts module** auto-imported via `import-tree`
- Modules register reusable config fragments via `flake.modules.<class>.<name>` (classes: `nixos`, `darwin`, `homeManager`)
- Host files in `hosts/` are **composition points** — they import dendritic modules and add host-specific config
- `modules/dendritic.nix` defines the `flake.modules` option (type: `deferredModule`)
- Host declarations access modules via `config.flake.modules.<class>.<name>` captured in let-bindings

### Module structure

```
modules/
  dendritic.nix              # Option definition for flake.modules
  foundation/                # Core: nix-settings, allow-unfree, common-server, locale-eu
  desktop/                   # pipewire, fonts, polkit, documentation
  desktop-env/               # cosmic, niri (window managers / DEs)
  security/                  # yubikey (nixos), gpg-agent (homeManager)
  networking/                # resolved-dns
  users/                     # heph (nixos), marco-darwin (darwin)
  home/                      # Home-manager modules
    hm-nixos-wiring.nix      # NixOS HM integration boilerplate
    hm-darwin-wiring.nix     # Darwin HM integration boilerplate
    editor/                  # helix, emacs
    terminal/                # ghostty, tmux
    tools/                   # direnv, git-heph, dev-tools, ssh-hosts
    shell/                   # zsh-p10k
    browser/                 # firefox
```

### Host pattern

```nix
{ inputs, config, ... }:
let
  nixos = config.flake.modules.nixos;
  hm = config.flake.modules.homeManager;
in {
  flake.nixosConfigurations.hostname = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      nixos.allow-unfree
      nixos.common-server
      # ... more dendritic modules
      # + host-specific inline config
    ];
  };
}
```

## Hosts

| Host | Type | System | Notes |
|------|------|--------|-------|
| freya | Desktop | x86_64-linux | Main workstation. Cosmic DE, Steam, VFIO, Wacom, borgbackup |
| fenrir | Laptop | aarch64-linux | MacBook Air M1 (Asahi). Niri WM, Noctalia shell |
| aron | Laptop | aarch64-darwin | MacBook Pro. nix-darwin, Homebrew |
| hermes | VPS | x86_64-linux | Hetzner. Mail server, Caddy, sops-nix |
| tyr | Server | x86_64-linux | Intel NUC. k3s, Prometheus, Homebox, Vaultwarden, Miniflux, Grafana |
| sauron | NAS | x86_64-linux | Jellyfin, *arr stack, Paperless, Minecraft, ZFS, disko |
| zima | Server | x86_64-linux | ZimaBoard. Docker, k3s agent, Atuin, nginx |
| timballo | Laptop | x86_64-linux | ThinkPad T480. Hyprland, LUKS |
| pixie | Phone | aarch64-linux | Pixel 6a (AVF). Minimal |
| ushi | Virtual | x86_64-linux | NixOS WSL 2. Minimal |
| fafnir | Router | — | Commented out. VLANs, PPPoE, NAT |

## Secrets

- **agenix** for NixOS system secrets (most hosts)
- **sops-nix** for hermes
- Secret files in `secrets/*.age`, metadata in `secrets/secrets.nix`
- Service modules reference secrets via `../../secrets/foo.age` (relative from host dir)

## Build & Deploy

```bash
# Enter dev shell
nix develop

# Build a host
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Deploy (on target machine)
sudo nixos-rebuild switch --flake .#<host>

# Darwin
darwin-rebuild switch --flake .#aron
```

## Known pre-existing issues

- `tyr/miniflux.nix`: uses `services.miniflux.environmentFiles` which no longer exists in nixpkgs
- `sauron/freya`: disko fetched via `fetchTarball` with stale hash — should migrate to flake input
- `fenrir`: Asahi firmware assertion fails without actual Apple hardware firmware
- `timballo`: `sound.enable` deprecated in current nixpkgs

## Conventions

- Formatter: `nixpkgs-fmt`
- Domain: `pochi.casa` for public services, `*.hephnet.lan` for local
- Caddy with Cloudflare DNS plugin for TLS on tyr and sauron
- All servers get `common-server` module (fail2ban, openssh, tailscale, netdata)
- User: `heph` on Linux hosts, `marco` on Darwin
