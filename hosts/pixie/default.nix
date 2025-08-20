# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
    # include nixos-avf modules
  ];

  avf.defaultUser = "droid";
  services.openssh.enable = true;
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--ssh" ];
  };

  environment.systemPackages = with pkgs; [
    mg vim htop ncdu
  ];

  system.stateVersion = "25.11"; # Did you read the comment?
}
