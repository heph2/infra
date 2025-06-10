{ config, lib, pkgs, modulesPath, ... }:

{
  # imports =
  #   [ (modulesPath + "/installer/scan/not-detected.nix")
  #   ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/91a79908-acd4-4959-9ffc-5fa997faa404";
    fsType = "btrfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F087-0E41";
    fsType = "vfat";
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/2b21cf70-2ad1-4d38-af6e-b39325b5663d";
    fsType = "btrfs";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/52867305-3fb6-42b2-b4df-107b177b8785"; }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
