{ ... }:
{
  imports = [ ./disk-config.nix ];

  networking.hostName = "gengar";
  networking.useDHCP = true;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    efiInstallAsRemovable = true;
  };
  boot.loader.efi.canTouchEfiVariables = false;

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC51eQuI+8IAAN+5EsW0sZpwUvUXKnC8VJ+EPyZZ5ZHvpikT8sd/GoDUvgRbnuzJFn9Dro2QZD6U5/3x7xjanFqYrg5gw6iXzOPQFMeJpecvP1UBAtyOqBYT5cA5MXl+CJARsysH72E0Wrt4JeY8ys1Y8BTbLiWptql8BO25gJSZa+YVICbnrRMvQLmtF38bzDvxx7fNy1m5XGLxtrVFMzb5y1herbyOlanEQwPAlJZcYnk00DWzD58Qm6d4iZh1O3FYkGF5lPJxzjkGMl/1lWR2yl7ewGFOsJm8rlME90zeLU6CIRvy7VOJaXzfVQz4YpBLthgJ+Hbb3YGgoQAyAolfY7Fy00m1WHaiKjXdgK+/Gkgc/YmJBIlfURr2a1TuRmkHVr76L4wvx2P+gNc34YVqxiid9ueJqTtrEme1+KwknTugaSybw3MxetJKAXEtAdT6DcyIb6uW7RiyKPHJ3xEV0RdvZDdvPRYB8IrqaEpmJ2UqGq/xJsQAO9g7kE6w2M= heph@fenrir.hephnet.lan"
  ];
  users.users.ubuntu = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC51eQuI+8IAAN+5EsW0sZpwUvUXKnC8VJ+EPyZZ5ZHvpikT8sd/GoDUvgRbnuzJFn9Dro2QZD6U5/3x7xjanFqYrg5gw6iXzOPQFMeJpecvP1UBAtyOqBYT5cA5MXl+CJARsysH72E0Wrt4JeY8ys1Y8BTbLiWptql8BO25gJSZa+YVICbnrRMvQLmtF38bzDvxx7fNy1m5XGLxtrVFMzb5y1herbyOlanEQwPAlJZcYnk00DWzD58Qm6d4iZh1O3FYkGF5lPJxzjkGMl/1lWR2yl7ewGFOsJm8rlME90zeLU6CIRvy7VOJaXzfVQz4YpBLthgJ+Hbb3YGgoQAyAolfY7Fy00m1WHaiKjXdgK+/Gkgc/YmJBIlfURr2a1TuRmkHVr76L4wvx2P+gNc34YVqxiid9ueJqTtrEme1+KwknTugaSybw3MxetJKAXEtAdT6DcyIb6uW7RiyKPHJ3xEV0RdvZDdvPRYB8IrqaEpmJ2UqGq/xJsQAO9g7kE6w2M= heph@fenrir.hephnet.lan"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "26.05";
}
