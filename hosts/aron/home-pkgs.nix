{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    (pkgs.emacsWithPackagesFromUsePackage {
      config = ./emacs.el;
      defaultInitFile = true;
      # package = pkgs.emacs-macport;
      package = pkgs.emacs-git;
      alwaysEnsure = true;
      extraEmacsPackages = epkgs: [
        epkgs.vterm
        epkgs.transient
        epkgs.notmuch
        epkgs.mu4e
        epkgs.pdf-tools
        epkgs.treesit-grammars.with-all-grammars
      ];
    })
    (pkgs.callPackage ../../pkgs/mblaze-tui.nix { })
    # (pkgs.callPackage ../../pkgs/amused.nix { })
    (pkgs.writers.writePython3Bin "jack" {
      flakeIgnore = [
        "E114"
        "E117"
        "E501"
        "E128"
        "E111"
        "E302"
        "E226"
        "E303"
        "E203"
        "W504"
        "E261"
        "W391"
        "F841"
      ];
      libraries =
        [ pkgs.python3Packages.requests pkgs.python3Packages.beautifulsoup4 ];
    } (builtins.readFile ../../pkgs/jack.py))
    aerc
    copilot-language-server
    age
    passage
    nb
    chawan
    jsonnet
    sketchybar
    gopls
    ncdu
    llama-cpp
    nixos-rebuild
    zls
    zig
    poppler
    ffmpegthumbnailer
    mediainfo
    thefuck
    imagemagick
    yubikey-manager
    clojure
    colima
    localsend
    delta
    starship
    devenv
    bat
    fd
    hledger
    ledger
    wezterm
    swc
    dive
    tree
    tshark
    act
    cmake
    netcat
    catgirl
    zathura
    docker-client
    jq
    ytfzf
    gitflow
    got
    wget
    postgresql
    coreutils
    terraform
    caddy
    bun
    nest-cli
    openscad-unstable
    openscad-lsp
    kubernetes-helm
    helix
    kubeseal
    packer
    qemu
    kustomize
    k9s
    kubectl
    krew
    mblaze
    argocd
    kubernetes-helm
    cowsay
    hexedit
    ffmpeg
    # ansible
    openssl
    yamllint
    timewarrior
    kubo
    gnumake42
    libqalculate
    lazygit
    mg
    k6
    swaks
    ngrok
    nodePackages.npm
    nodePackages.pnpm
    nodePackages.typescript
    nodePackages.npm-check-updates
    nodejs
    yarn
    perl
    openstackclient
    alacritty
    innernet
    wireguard-go
    wireguard-tools
    openvpn
    easyrsa
    nginx
    nmap
    meld
    android-tools
    tailscale
  ];
}
