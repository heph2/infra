{
  description = "Infrastructure flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable-nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stardew-modding = {
      url = "github:Distracted-E421/stardew-modding-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    avf = {
      url = "github:nix-community/nixos-avf";
    };
    nur.url = "github:nix-community/NUR";
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url = "github:ryantm/agenix";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    trcc_gif = {
      url = "git+https://codeberg.org/heph/trcc_gif";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay/db47b2483942771a725cf10e7cd3b1ec562750b7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        #./hosts/fafnir/default.nix ## Router
        ./hosts/freya/configuration.nix # # Desktop
        ./hosts/hermes/configuration.nix # # Hetzner VPS
        ./hosts/tyr/configuration.nix # # Intel NUC
        ./hosts/timballo/configuration.nix # # Laptop t480
        ./hosts/zima/configuration.nix # # ZimaBoard
        ./hosts/ushi/configuration.nix # # Nixos WSL 2
        ./hosts/sauron/configuration.nix # # NAS
        ./hosts/aron/configuration.nix # # MacBook
        ./hosts/pixie/configuration.nix # # Google Pixel 6a AVF
        ./dev.nix
      ];
      systems = [
        # systems for which you want to build the `perSystem` attributes
        "x86_64-linux"
        "aarch64-darwin"
        "aarch64-linux"
      ];
    };
}
