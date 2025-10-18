{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  user = "heph";
  platform = "amd";
  vfioIds = [
    "10de:2204"
    "10de:1aef"
  ];
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disk-config.nix
    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
  ];

  # specialisation."VFIO".configuration = {
  #   imports = [ ./vfio.nix ];
  #   system.nixos.tags = [ "with-vfio" ];
  #   vfio.enable = true;
  # };
  #
  #
  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
  ];
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

  environment.extraInit = ''
    xset s off -dpms
  '';

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  security.polkit.enable = true;
  services.blueman.enable = true;
  services.zfs.autoScrub.enable = true;

  services.borgbackup.jobs =
    let
      common-excludes = [
        ".cache"
        "*/cache2" # firefox
        "*/Cache"
        ".mozilla"
        "*/.cargo"
        ".compose-cache"
        ".npm"
        ".local/share"
        ".ollama"
        "*/.terraform.d"
        ".rustup"
        ".config/Slack/logs"
        ".config/Code/CachedData"
        ".container-diff"
        ".npm/_cacache"
        "*/node_modules"
        "*/_build"
        "*/.tox"
        "*/venv"
        "*/.venv"
      ];
      basicBorgJob = name: {
        encryption.mode = "none";
        environment.BORG_RSH = "ssh -o 'StrictHostKeyChecking=no' -i /home/heph/.ssh/sekai_ed";
        environment.BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
        extraCreateArgs = "--verbose --stats --checkpoint-interval 600";
        repo = "ssh://zima//data/backup/${name}";
        compression = "zstd,1";
        startAt = "hourly";
        persistentTimer = true;
        user = "heph";
      };
    in
    {
      home-heph = basicBorgJob "freya/home-heph" // rec {
        paths = "/home/heph";
        exclude = map (x: paths + "/" + x) (
          common-excludes
          ++ [
            "Downloads"
            "Videos"
            ".models"
          ]
        );
      };
    };

  services.samba = {
    enable = false;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";
        "hosts allow" = "192.168.1. 192.168.122. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "public" = {
        "path" = "/home/heph/Public";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "username";
        "force group" = "groupname";
      };
    };
  };

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  services.samba-wsdd = {
    enable = false;
    openFirewall = true;
  };

  programs.steam = {
    enable = true;
  };

  services.transmission = {
    enable = false;
    user = "heph";
    group = "users";
    home = "/home/heph/";
    settings.download-dir = "/home/heph/Videos";
    settings.incomplete-dir = "/home/heph/Videos/.incomplete";
    settings.downloadDirPermissions = "0770";
  };

  services.fstrim = {
    enable = true;
  };
  nixpkgs.config.allowUnfree = true;

  #  services.xremap = {
  #    withX11 = false;
  #    serviceMode = "system";
  #    debug = false;
  #  };
  #  services.xremap.config.keymap = [{
  #    name = "Google Chrome";
  #    application.only = [ "Chromium-browser" ];
  #    remap = { "Super-s" = "C-f"; };
  #  }];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
  };

  hardware.cpu.amd.updateMicrocode = true;
  networking.hostId = "d81f3ea4";
  nix.settings.trusted-substituters = [ "https://ai.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
  ];

  boot.extraModprobeConfig = ''
    blacklist nouveau
    options nouveau modeset=0
  '';

  boot.kernelModules = [
    "kvm-${platform}"
    "vfio_virqfd"
    "vfio_pci"
    "vfio_iommu_type1"
    "vfio"
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  ## Nvidia

  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = false;
  #   powerManagement.finegrained = false;
  #   open = false;
  #   nvidiaSettings = true;
  # };

  # hardware.nvidia.prime = {
  #   offload.enable = true;
  #   nvidiaBusId = "PCI:7:0:0";
  #   amdgpuBusId = "PCI:4:0:0";
  # };

  ## yubikey
  services.pcscd.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="87ad", ATTR{idProduct}=="70db", MODE="0666"
  '';
  services.udev.packages = [
    pkgs.libfido2
    pkgs.yubikey-personalization
  ];
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
  programs = {
    yubikey-touch-detector.enable = true;
  };
  hardware.gpgSmartcards.enable = true;
  services.yubikey-agent.enable = true;

  programs.zsh.enable = true;

  ## Blacklist Nouveau drivers
  boot.blacklistedKernelModules = [ "nouveau" ];

  systemd.tmpfiles.rules = [ "f /dev/shm/looking-glass 0660 ${user} kvm -" ];

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

  hardware.enableAllFirmware = true;
  hardware.steam-hardware.enable = true;
  hardware.xpadneo.enable = true;
  hardware.graphics.enable = true;
  hardware.bluetooth.enable = true;

  networking.hostName = "freya"; # Define your hostname.
  time.timeZone = "Europe/Rome";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.xrandrHeads = [
    {
      output = "HDMI-A-0";
      primary = true;
    }
    { output = "DisplayPort-1"; }
  ];

  services.xserver.videoDrivers = [ "amdgpu" ];

  # services.displayManager.defaultSession = "none+i3";
  # services.xserver.displayManager = {
  #   #ly.enable = true;
  # };

  # services.xserver.displayManager.sessionCommands = ''
  #   ${pkgs.xorg.xinput} set-prop 'ELECOM TrackBall Mouse DEFT Pro TrackBall Mouse' 'libinput Accel Speed' -0.5
  # '';

  # services.xserver = { windowManager.i3.enable = true; };

  services.emacs.enable = true;

  services.displayManager.ly.enable = false;
  services.xserver.desktopManager.plasma5.enable = false;

  services.xserver.xkb.layout = "us";
  services.printing.enable = true;

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.ollama = {
    enable = false;
    host = "0.0.0.0";
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "32768";
    };
    acceleration = "cuda";
    openFirewall = true;
  };

  services.open-webui = {
    enable = false; # currently broken
  };

  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
    in
    {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        shuffle # shuffle+ (special characters are sanitized out of extension names)
      ];
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
    };

  programs.streamdeck-ui = {
    enable = true;
    autoStart = true; # optional
  };

  users.users.heph = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "qemu-libvirtd"
      "libvirtd"
      "disk"
      "kvm"
      "docker"
      "plugdev"
      "dialout"
    ];
  };

  services.synergy.server = {
    enable = false;
    autoStart = false;
    screenName = "freya";
    address = "0.0.0.0:24800";
    tls.enable = false;
  };

  virtualisation = {
    docker = {
      enable = true;
    };
  };

  users.users.root = {
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK heph@fenrir"
      ];
    };
  };

  documentation.dev.enable = true;
  documentation.man = {
    man-db.enable = false;
    mandoc.enable = true;
  };

  environment.systemPackages = with pkgs; [
    inputs.nix-ai-tools.packages.${pkgs.system}.claude-code
    vim
    hidapi
    wget
    quickemu
    python3
    aider-chat
    firefox
    man-pages
    man-pages-posix
    ffmpeg
    kubectl
    bind
    fd
    smartmontools
    nvme-cli
    nixfmt-classic
    inetutils
    openssl
    virt-manager
    looking-glass-client
    pciutils
    usbutils
    mg
    git
    docker-compose
    podman-tui
    remmina
    barrier
    lm_sensors
    rofi
    dive
    dmenu
    sxhkd
    bspwm
    btrfs-assistant
  ];

  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      onBoot = "start";
      onShutdown = "shutdown";
    };
  };

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
    24800
    57621
  ];
  networking.firewall.allowedUDPPorts = [
    24800
    5353
  ];
  networking.firewall.enable = true;
  networking.firewall = {
    extraCommands = ''
      iptables -I INPUT 1 -i docker0 -p tcp -d 172.17.0.1 -j ACCEPT
      iptables -I INPUT 2 -i docker0 -p udp -d 172.17.0.1 -j ACCEPT
    '';
  };
  networking.firewall.trustedInterfaces = [ "virbr0" ];
  # networking.interfaces.enp6s0.wakeOnLan.enable = true;

  system.stateVersion = "23.11";
}
