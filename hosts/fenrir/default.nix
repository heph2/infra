{ config, lib, pkgs, inputs, ... }:
let
  user = "heph";
  home = "/home/${user}";
in {
      
  imports = [
    ./hardware-configuration.nix
    ./apple-silicon-support
   ];

  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = false;

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  networking.hostName = "fenrir";
  time.timeZone = "Europe/Rome";

  networking.networkmanager.enable = true;
  networking.wireless.enable = false;

  networking.dhcpcd = {
    enable = true;
    extraConfig = "nohook resolv.conf";
  };
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    dnsovertls = "true";
  };
  networking.nameservers =
    [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  nixpkgs.config.allowUnfree = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      extra-substituters = [
        "https://noctalia.cachix.org"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  security.polkit.enable = true;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
    pulse.enable = true;
  };

  services.pcscd.enable = true;
  hardware.gpgSmartcards.enable = true;
  services.yubikey-agent.enable = true;
  programs.yubikey-touch-detector.enable = true;

  services.gnome.evolution-data-server.enable = true;

  programs.zsh.enable = true;

  environment.variables = { EDITOR = "hx"; };

  environment.localBinInPath = true;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.hack
      fantasque-sans-mono
      hack-font
      fira-code
      font-awesome
    ];
  };

  documentation.dev.enable = true;
  documentation.man = {
    man-db.enable = false;
    mandoc.enable = true;
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri-stable;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.greetd}/bin/agreety --cmd niri";
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gnome ];
  };

  users.users.heph = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" "networkmanager" "plugdev" "dialout" ];
  };

  users.users.root = {
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK heph@fenrir"
      ];
    };
  };

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.nix-ai-tools.packages.${pkgs.system}.opencode
    vim
    wget
    curl
    git
    fd
    nh
    nixfmt-rfc-style
    lm_sensors
    pciutils
    usbutils
    brightnessctl
    cliphist
    man-pages
    man-pages-posix
    smartmontools
    nvme-cli
    inetutils
    openssl
    age
    age-plugin-yubikey
    passage
    yubikey-manager
    yubikey-touch-detector
    libfido2
    yubikey-personalization
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.enable = true;

  system.stateVersion = "25.05";
}
