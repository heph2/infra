{ config, lib, pkgs, ... }: {

  wsl.enable = true;
  wsl.defaultUser = "nixos";

  services.openssh = {
    enable = true;
    ports = [ 2222 ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJBwkxucypqmAsuY/n51EsoEDQaog4u/WOl0i69NY+GN marco@steel.local"
  ];
  system.stateVersion = "23.11";
}
