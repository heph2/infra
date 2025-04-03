{
  description = "Infrastructure flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        #./hosts/fafnir/default.nix ## Router
        ./hosts/freya/configuration.nix ## Desktop
        ./hosts/hermes/configuration.nix ## Hetzner VPS
        #./hosts/tyr/default.nix ## Intel NUC
        ./hosts/timballo/configuration.nix ## Laptop t480
        ./hosts/zima/configuration.nix ## ZimaBoard
        ./hosts/ushi/configuration.nix ## Nixos WSL 2
        ./dev.nix
      ];
      systems = [
        # systems for which you want to build the `perSystem` attributes
        "x86_64-linux"
        "aarch64-darwin"
      ];
    };
}
