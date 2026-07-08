{
  config,
  pkgs,
  lib,
  agenix,
  stardew-modding,
  firefox-addons,
  inputs,
  ...
}:

let
  cfg = config.xsession.windowManager.i3;
  awsBestPracticesSkill = pkgs.runCommand "aws-best-practices-skill" { } ''
        cp -R ${inputs.aws-best-practices-skill} $out
        chmod -R u+w $out
        cat > $out/SKILL.md <<'EOF'
    ---
    name: aws-best-practices
    description: Local AWS best-practices catalog. Use for AWS Well-Architected/security/reliability/performance/cost/operations/sustainability guidance. Read local catalog files first; avoid web unless user asks for live verification or local coverage is missing.
    ---
    EOF
        awk 'BEGIN { frontmatter = 0; body = 0 } /^---$/ { frontmatter++; if (frontmatter == 2) { body = 1; next } } body { print }' ${inputs.aws-best-practices-skill}/SKILL.md >> $out/SKILL.md
  '';
  piSkills = {
    chrome-cdp = inputs.chrome-cdp-skill + "/skills/chrome-cdp";
    grill-me = inputs.mattpocock-skills + "/skills/productivity/grill-me";
    imagegen = inputs.openai-skills + "/skills/.system/imagegen";
    ponytail = inputs.ponytail + "/skills/ponytail";
    tdd = inputs.superpowers + "/skills/test-driven-development";
    aws-best-practices = awsBestPracticesSkill;
    nixos-host-workflow = ../../skills/nixos-host-workflow;
  };
in
{
  imports = [
    agenix.homeManagerModules.default
    stardew-modding.homeManagerModules.default
    inputs.pi.homeModules.default
    #    ../../modules/graphical/firefox/default.nix
  ];

  home.username = "heph";
  home.homeDirectory = "/home/heph";
  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;
  programs.home-manager.enable = true;

  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
  };

  home.file.".pi/agent/sandbox.json".text = builtins.toJSON {
    enabled = true;
    allowBrowserProcess = true;
    network = {
      allowLocalBinding = true;
      allowAllUnixSockets = true;
      allowedDomains = [
        "localhost"
        "127.0.0.1"
        "html.duckduckgo.com"
        "*.npmjs.org"
        "*.pypi.org"
        "*.github.com"
        "raw.githubusercontent.com"
        "mcp.context7.com"
      ];
      deniedDomains = [ ];
    };
    filesystem = {
      denyRead = [ "/Users" ];
      allowRead = [
        "."
        "~/projects"
        "~/.config"
        "~/.cargo"
        "~/.local"
        "~/Library"
        "~/.cache"
        "/Applications/Google Chrome.app"
        "/System/Volumes/Data/Applications/Google Chrome.app"
      ];
      allowWrite = [
        "."
        "/tmp"
        "~/.pi/"
        "~/.cache/uv"
        "~/.rustup"
        "~/.agent-browser"
        "~/Library/Application Support/Google/Chrome"
        "~/Library/Application Support/Google/Chrome for Testing/Crashpad"
      ];
      denyWrite = [
        ".env"
        ".env.*"
        "*.pem"
        "*.key"
      ];
    };
  };

  home.file.".pi/agent/themes/catpuccino-mocha.json".text = builtins.toJSON {
    "$schema" =
      "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
    name = "catpuccino-mocha";
    vars = {
      rosewater = "#f5e0dc";
      flamingo = "#f2cdcd";
      pink = "#f5c2e7";
      mauve = "#cba6f7";
      red = "#f38ba8";
      maroon = "#eba0ac";
      peach = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      teal = "#94e2d5";
      sky = "#89dceb";
      sapphire = "#74c7ec";
      blue = "#89b4fa";
      lavender = "#b4befe";
      text = "#cdd6f4";
      subtext1 = "#bac2de";
      subtext0 = "#a6adc8";
      overlay2 = "#9399b2";
      overlay1 = "#7f849c";
      overlay0 = "#6c7086";
      surface2 = "#585b70";
      surface1 = "#45475a";
      surface0 = "#313244";
      base = "#1e1e2e";
      mantle = "#181825";
      crust = "#11111b";
    };
    colors = {
      accent = "mauve";
      border = "surface2";
      borderAccent = "mauve";
      borderMuted = "surface1";
      success = "green";
      error = "red";
      warning = "yellow";
      muted = "overlay2";
      dim = "overlay0";
      text = "text";
      thinkingText = "subtext0";
      selectedBg = "surface0";
      userMessageBg = "surface0";
      userMessageText = "text";
      customMessageBg = "surface0";
      customMessageText = "text";
      customMessageLabel = "mauve";
      toolPendingBg = "mantle";
      toolSuccessBg = "#1e3326";
      toolErrorBg = "#3a202e";
      toolTitle = "blue";
      toolOutput = "text";
      mdHeading = "mauve";
      mdLink = "blue";
      mdLinkUrl = "sapphire";
      mdCode = "peach";
      mdCodeBlock = "text";
      mdCodeBlockBorder = "surface2";
      mdQuote = "subtext0";
      mdQuoteBorder = "surface2";
      mdHr = "surface2";
      mdListBullet = "mauve";
      toolDiffAdded = "green";
      toolDiffRemoved = "red";
      toolDiffContext = "overlay1";
      syntaxComment = "overlay1";
      syntaxKeyword = "mauve";
      syntaxFunction = "blue";
      syntaxVariable = "text";
      syntaxString = "green";
      syntaxNumber = "peach";
      syntaxType = "yellow";
      syntaxOperator = "sky";
      syntaxPunctuation = "overlay2";
      thinkingOff = "overlay0";
      thinkingMinimal = "lavender";
      thinkingLow = "blue";
      thinkingMedium = "teal";
      thinkingHigh = "peach";
      thinkingXhigh = "red";
      bashMode = "green";
    };
    export = {
      pageBg = "base";
      cardBg = "mantle";
      infoBg = "surface0";
    };
  };

  age = {
    identityPaths = [ "/home/heph/.ssh/sekai_ed" ];
    secrets = {
      imap-mbauce = {
        file = ../../secrets/imap-mbauce-mail.age;
      };
    };
  };

  programs.pi.coding-agent = {
    enable = true;
    skills = builtins.attrValues piSkills;
    settings = {
      hideThinkingBlock = true;
      theme = "catpuccino-mocha";
      packages = [
        # Agent orchestration and explicit goal tracking.
        "npm:pi-subagents@0.33.1"
        "npm:@narumitw/pi-goal@0.9.2"

        # Safer operation: sandbox bash/read/write/edit behind .pi/sandbox.json.
        "git:github.com/carderne/pi-sandbox@d14e15a76b4ae030b07bdd3e6f42732ed3636679"

        # Research and context tools: search/fetch/PDF/video plus skill UX polish.
        "npm:pi-web-access@0.13.0"
        "npm:pi-skillful@0.3.11"
        "npm:@eko24ive/pi-ask@1.1.0"
        "npm:pi-tool-display@0.5.0"
        "npm:pi-powerline-footer@0.6.1"
        "npm:@quintinshaw/pi-dynamic-workflows@2.11.0"
        "npm:@victor-software-house/pi-agent-browser"
      ];
    };
  };

  programs.stardew-modding.enable = true;
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    extraPackages = epkgs: [
      epkgs.nix-mode
      epkgs.nixfmt
      epkgs.vterm
      (epkgs.treesit-grammars.with-all-grammars)
    ];
    extraConfig = builtins.readFile "/home/heph/.emacs.d/init.el";
  };

  programs.kitty.enable = true;

  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require("wezterm")

      local config = wezterm.config_builder()

      config.color_scheme = "rose-pine-moon"
      config.font = wezterm.font("Hack Nerd Font")
      config.font_size = 15.0
      config.window_background_opacity = 0.8
      config.macos_window_background_blur = 50
      config.hide_tab_bar_if_only_one_tab = true
      config.window_decorations = "RESIZE"

      return config
    '';
  };

  home.file.".config/herdr/config.toml".text = ''
    [keys]
    prefix = "ctrl+b"
    focus_pane_left  = "prefix+h"
    focus_pane_down  = "prefix+j"
    focus_pane_up    = "prefix+k"
    focus_pane_right = "prefix+l"
    split_horizontal = "prefix+double_quote"
    split_vertical    = "prefix+percent"
    new_tab   = "prefix+c"
    close_tab = "prefix+ampersand"
    workspace_picker = "prefix+w"
    goto             = "prefix+g"
    copy_mode  = "prefix+y"  # herdr's copy-mode entry key; copy-mode's own internal keys (v/space select, y/Enter copy, q/Esc cancel) aren't configurable
  '';

  home.packages =
    with pkgs;
    [
      (pkgs.writers.writePython3Bin "totp" { } (builtins.readFile ../../pkgs/totp.py))
      bitwig-studio
      wootility
      mpv
      dwarf-fortress
      thunar
      aporetic
      agent-browser
      w3m
      kdePackages.okular
      hledger
      jujutsu
      lazygit
      ripgrep
      bubblewrap
      socat
      xournalpp
      python313Packages.python-lsp-server
      obsidian
      sdrpp
      libnotify
      gqrx
      forge-mtg
      vscodium
      nodejs
      blender
      vivaldi
      gelly
      feishin
      openscad
      openscad-lsp
      fuse-overlayfs
      dwarfs
      vesktop
      # prismlauncher
      mangohud
      psmisc
      nmap
      shadps4
      easyeffects
      high-tide
      winbox
      rpcs3
      deltachat-desktop
      bambu-studio
      orca-slicer
      nix-output-monitor
      brave
      speedtest-cli
      ispell
      transmission_4-qt
      libreoffice
      bottles
      lazygit
      ranger
      gnumake
      xclip
      id3v2
      jq
      pnpm_10
      jless
      feh
      trayer
      chiaki-ng
      xscreensaver
      reaper
      nautilus
      gamemode
      delta
      cheese
      playerctl
      godot_4
      ardour
      via
      ncdu
      unzip
      afew
      scrot
      telegram-desktop
      pwvucontrol
      alsa-utils
      wireplumber
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
      devenv
      anki
      gh
      git-annex
      faugus-launcher
      chromium
      age
      age-plugin-yubikey
      passage
      yubikey-manager
      yubikey-touch-detector
      yubikey-agent
      libu2f-host
      pam_u2f
      rclone
    ]
    ++ (with haskellPackages; [
      ghcid
      xmobar
      yeganesh
    ]);

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*".addKeysToAgent = "yes";
      zima = {
        port = 22;
        hostname = "192.168.0.105";
        user = "root";
        identityFile = "/home/heph/.ssh/sekai_ed";
      };
      fenrir = {
        port = 22;
        hostname = "192.168.0.165";
        user = "root";
        identityFile = "/home/heph/.ssh/sekai_ed";
      };
      vellutata = {
        port = 22;
        hostname = "193.57.159.213";
        user = "vellutata";
        identityFile = "/home/heph/.ssh/asn_id";
      };
      "vellutata.senza.cloud" = {
        port = 22;
        hostname = "vellutata.senza.cloud";
        user = "vellutata";
        identityFile = "/home/heph/.ssh/asn_id";
      };
      "risotto.senza.cloud" = {
        port = 22;
        hostname = "risotto.senza.cloud";
        user = "risotto";
        identityFile = "/home/heph/.ssh/asn_id";
      };
      risotto = {
        port = 22;
        hostname = "5.231.80.72";
        user = "risotto";
        identityFile = "/home/heph/.ssh/asn_id";
      };
      hermes = {
        port = 22;
        hostname = "135.181.85.238";
        user = "root";
        identityFile = "/home/heph/.ssh/sekai_ed";
      };
      tyr = {
        port = 22;
        hostname = "192.168.0.104";
        user = "root";
        identityFile = "/home/heph/.ssh/sekai_ed";
      };
      github = {
        port = 22;
        hostname = "github.com";
        user = "git";
        identityFile = "/home/heph/.ssh/sr-ht_rsa";
      };
      remarkable = {
        port = 22;
        hostname = "10.11.99.1";
        user = "root";
        identityFile = "/home/heph/.ssh/test-id_rsa";
      };
      sauron = {
        port = 22;
        hostname = "192.168.0.106";
        user = "root";
        identityFile = "/home/heph/.ssh/sekai_ed";
      };
      # Tailscale SSH
      pixie = {
        hostname = "pixie";
        user = "root";
      };
    };
  };

  # custom afew config
  home.file.".config/afew/config".text = ''
    [SpamFilter]
    [KillThreadsFilter]
    [ListMailsFilter]
    [SentMailsFilter]
    sent_tag = sent
    [ArchiveSentMailsFilter]

    [Filter.0]
    message = "Filter Personal Mails"
    query = 'folder:~/Maildir/personal/'
    tags = +personal

    [Filter.1]
    message = "delete all message from fitexpress"
    query = from:no_reply@fitexpress.it
    tags = +junk;-new

    [Filter.2]
    message = "Filter mailing lists"
    query = from:nexa@server-nexa.polito.it
    tags = +lists;-new

    [Filter.3]
    message = "Filter Work Mails"
    query = 'to:m.bauce@davinci.care'
    tags = +work

    [Filter.4]
    message = "Filter OVH Mails"
    query = 'folder:~/Maildir/ovh/'
    tags = +ovh

    [InboxFilter]
  '';

  # handle aliases
  home.file.".config/aliases".text = ''
    root: shopping@mbauce.com
  '';

  home.file.".config/helix/yazi-picker.sh".text = ''
    #!/usr/bin/env bash

    paths=$(yazi "$2" --chooser-file=/dev/stdout | while read -r; do printf "%q " "$REPLY"; done)

    if [[ -n "$paths" ]]; then
    	zellij action toggle-floating-panes
    	zellij action write 27 # send <Escape> key
    	zellij action write-chars ":$1 $paths"
    	zellij action write 13 # send <Enter> key
    else
    	zellij action toggle-floating-panes
    fi
  '';

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    extraConfig = ''
      set-option -g mouse on
      set -g extended-keys on
      set -g extended-keys-format csi-u
      bind-key h split-window -v
      bind-key v split-window -h
    '';
  };

  programs.nushell = {
    enable = false;
  };

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd z" ];
    };

    bash.enable = true;
  };

  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";
  };

  programs.zellij = {
    enable = true;
  };

  services.picom = {
    enable = true;
    activeOpacity = 0.99;
    inactiveOpacity = 0.95;
    backend = "glx";
    fade = true;
    fadeDelta = 5;
    opacityRules = [ "100:name *= 'i3lock'" ];
    shadow = true;
    shadowOpacity = 0.85;
  };

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      window-decoration = "none";
    };
  };
  programs.rofi = {
    enable = true;
    theme = "arthur";
    terminal = "${pkgs.alacritty}/bin/alacritty";
    plugins = [
      pkgs.rofi-calc
      pkgs.rofi-power-menu
    ];
    extraConfig = {
      modi = "combi";
      combi-modi = "windowcd,drun,ssh";
      run-shell-command = "sudo virsh start win11-2";
    };
  };

  programs.helix = {
    enable = true;
    settings = {
      theme = "autumn_night_transparent";
      editor.cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
      # keys.normal = {
      #  C-y = ":sh zellij run -n Yazi -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh open";
      #};
      keys.normal.C-y = {
        y = ":sh zellij run -n Yazi -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh open";
        v = ":sh zellij run -n Yazi -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh vsplit";
        h = ":sh zellij run -n Yazi -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh hsplit";
      };
    };
    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.nixfmt;
      }
    ];
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };
  programs.fzf = {
    enable = true;
  };
  programs.htop.enable = true;
  programs.zathura.enable = true;
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 36000;
    maxCacheTtl = 36000;
    defaultCacheTtlSsh = 36000;
    maxCacheTtlSsh = 36000;
    extraConfig = ''
      pinentry-program ${pkgs.pinentry-qt}/bin/pinentry
    '';
  };
  services.blueman-applet.enable = true;
  services.flameshot.enable = true;
  services.unclutter.enable = true;
  services.emacs.enable = true;
  programs.k9s.enable = true;

  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = false;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      OfferToSaveLoginsDefault = false;
      PasswordManagerEnabled = false;
      FirefoxHome = {
        Search = true;
        Pocket = false;
        Snippets = false;
        TopSites = false;
        Highlights = false;
      };
      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
      };
    };
    profiles.default = {
      id = 0;
      name = "heph";
      isDefault = true;
      extensions.packages = with firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
        ublock-origin
        bitwarden
        user-agent-string-switcher
        multi-account-containers
        kagi-search
      ];
      settings = {
        # Vertical tabs (native Firefox 131+)
        "sidebar.verticalTabs" = true;
        "sidebar.revamp" = true;

        # Privacy
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.search.suggest.enabled" = false;
        "browser.search.suggest.enabled.private" = false;
        "browser.urlbar.suggest.searches" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "app.shield.optoutstudies.enabled" = false;

        # Performance / Hardware acceleration
        "media.ffmpeg.vaapi.enabled" = true;
        "media.rdd-vpx.enabled" = true;
        "gfx.webrender.all" = true;
        "layers.acceleration.force-enabled" = true;

        # UI / UX
        "browser.tabs.drawInTitlebar" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "general.smoothScroll" = true;
        "browser.sessionstore.resume_from_crash" = true;
        "browser.tabs.tabmanager.enabled" = false;

        # Use XDG portals for file picker
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "widget.use-xdg-desktop-portal.mime-handler" = 1;

        # Enable custom CSS
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
  };

  # systemd.user.services.mpris-proxy = {
  #   description = "Mpris proxy";
  #   after = [ "network.target" "sound.target" ];
  #   wantedBy = [ "default.target" ];
  #   serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  # };
  # programs = {
  #   atuin = {
  #     enable = true;
  #     enableZshIntegration = true;
  #     settings = {
  #       dialect = "us";
  #       style = "compact";
  #       inline_height = 15;
  #     };
  #   };
  # };

  programs.zsh = {
    enable = true;
    initContent = "source ~/.p10k.zsh";
    shellAliases = {
      a = "amused";
      d = "docker";
      ll = "ls -l";
      mg = "mg -n";
      zzz = "shutdown now";
      lz = "lazygit";
      k = "kubectl";
      ks = "kubectl config get-contexts |  awk 'NR>1 { print $2 }' | fzf | xargs kubectl config use-context";
      update = "sudo nixos-rebuild switch";
      game = "sudo virsh start win11-2";
    };
    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; } # Simple plugin installation
        {
          name = "romkatv/powerlevel10k";
          tags = [
            "as:theme"
            "depth:1"
          ];
        } # Installations with additional options. For the list of options, please refer to Zplug README.
      ];
    };
  };

  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings = {
      user.email = "srht@mrkeebs.eu";
      user.name = "heph";
      aliases = {
        gp = "add -p";
        co = "checkout";
        s = "switch";
        st = "status";
        month-exp = " hledger balance expenses --period thismonth -f ~/Documents/finance/2026.journal";
      };
      extraConfig = {
        pull.ff = "only";
        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";
        delta = {
          navigate = true;
          light = false;
          side-by-side = true;
        };
      };
      filter.annex = {
        clean = "git-annex smudge --clean -- %f";
        smudge = "git-annex smudge -- %f";
        process = "git-annex filter-process";
        required = true;
      };
    };
  };

  programs.mbsync.enable = true;
  programs.msmtp = {
    enable = true;
  };
  programs.aerc.extraConfig.general.unsafe-accounts-conf = true;
  programs.aerc = {
    enable = true;
    extraAccounts = {
      Personal = {
        source = "maildir://~/Maildir/personal";
        outgoing = "${pkgs.msmtp}/bin/msmtp";
        default = "INBOX";
        from = "Marco Bauce <me@mbauce.com>";
        copy-to = "Sent";
        check-mail-cmd = "mbsync personal";
        check-mail = "1m";
      };
    };
    extraConfig = {
      filters = {
        "text/html" = "w3m -T text/html";
      };
    };
  };
  programs.notmuch = {
    enable = true;
    hooks = {
      preNew = "mbsync --all";
      postNew = "afew -tnv";
    };
  };
  accounts.email = {
    accounts.personal = {
      address = "me@mbauce.com";
      imap.host = "mail.mbauce.com";
      mbsync = {
        enable = true;
        create = "maildir";
      };
      msmtp.enable = true;
      notmuch.enable = true;
      primary = true;
      realName = "Marco Bauce";
      passwordCommand = "${pkgs.coreutils-full}/bin/cat ${config.age.secrets.imap-mbauce.path}";
      smtp.host = "mail.mbauce.com";
      userName = "me@mbauce.com";
    };
    # accounts.ovh = {
    #   address = "hephaestus@mrkeebs.eu";
    #   imap.host = "ssl0.ovh.net";
    #   imap.tls.useStartTls = true;
    #   imap.port = 465;
    #   mbsync = {
    #     enable = true;
    #     create = "maildir";
    #   };
    #   msmtp.enable = true;
    #   notmuch.enable = true;
    #   realName = "Heph";
    #   passwordCommand = "passage show hephaestus@mrkeebs.eu";
    #   smtp.host = "pro2.mail.ovh.net";
    #   userName = "hephaestus@mrkeebs.eu";
    # };
    accounts.work = {
      address = "m.bauce@davinci.care";
      imap.host = "imap.gmail.com";
      mbsync = {
        enable = true;
        create = "maildir";
      };
      msmtp.enable = true;
      notmuch.enable = true;
      realName = "Marco Bauce";
      passwordCommand = "passage show m.bauce@davinci.care-oauth2";
      smtp.host = "smtp.gmail.com";
      userName = "m.bauce@davinci.care";
    };
  };
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "Inconsolata";
        markup = "full";
        format = "<b>%s</b>\\n%b";
        icon_position = "left";
        sort = true;
        alignment = "center";
        geometry = "500x60-15+49";
        browser = "firefox -new-tab";
        transparency = 10;
        word_wrap = true;
        show_indicators = false;
        separator_height = 2;
        padding = 6;
        horizontal_padding = 6;
        separator_color = "frame";
        frame_width = 2;
      };
      shortcuts = {
        close = "ctrl+space";
        close_all = "ctrl+shift+space";
        history = "ctrl+grave";
        context = "ctrl+shift+period";
      };
      urgency_low = {
        frame_color = "#3B7C87";
        foreground = "#3B7C87";
        background = "#191311";
        timeout = 4;
      };
      urgency_normal = {
        frame_color = "#5B8234";
        foreground = "#5B8234";
        background = "#191311";
        timeout = 6;
      };
      urgency_critical = {
        frame_color = "#B7472A";
        foreground = "#B7472A";
        background = "#191311";
        timeout = 8;
      };
    };
  };

  xsession.windowManager.i3 = {
    enable = false;
    package = pkgs.i3-gaps;
    config = {
      modifier = "Mod4";
      gaps = {
        inner = 10;
        outer = 5;
      };
      keybindings = {
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioPlay" = "exec playerctl play";
        "XF86AudioPause" = "exec playerctl pause";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl prev";
        "${cfg.config.modifier}+Return" = "exec ${cfg.config.terminal}";
        "${cfg.config.modifier}+Shift+q" = "kill";
        "${cfg.config.modifier}+d" = "exec ${cfg.config.menu}";

        "${cfg.config.modifier}+Left" = "focus left";
        "${cfg.config.modifier}+Down" = "focus down";
        "${cfg.config.modifier}+Up" = "focus up";
        "${cfg.config.modifier}+Right" = "focus right";

        "${cfg.config.modifier}+Shift+Left" = "move left";
        "${cfg.config.modifier}+Shift+Down" = "move down";
        "${cfg.config.modifier}+Shift+Up" = "move up";
        "${cfg.config.modifier}+Shift+Right" = "move right";

        "${cfg.config.modifier}+h" = "split h";
        "${cfg.config.modifier}+v" = "split v";
        "${cfg.config.modifier}+f" = "fullscreen toggle";

        "${cfg.config.modifier}+s" = "layout stacking";
        "${cfg.config.modifier}+w" = "layout tabbed";
        "${cfg.config.modifier}+e" = "layout toggle split";

        "${cfg.config.modifier}+Shift+space" = "floating toggle";
        "${cfg.config.modifier}+space" = "focus mode_toggle";

        "${cfg.config.modifier}+a" = "focus parent";

        "${cfg.config.modifier}+Shift+minus" = "move scratchpad";
        "${cfg.config.modifier}+minus" = "scratchpad show";

        "${cfg.config.modifier}+1" = "workspace number 1";
        "${cfg.config.modifier}+2" = "workspace number 2";
        "${cfg.config.modifier}+3" = "workspace number 3";
        "${cfg.config.modifier}+4" = "workspace number 4";
        "${cfg.config.modifier}+5" = "workspace number 5";
        "${cfg.config.modifier}+6" = "workspace number 6";
        "${cfg.config.modifier}+7" = "workspace number 7";
        "${cfg.config.modifier}+8" = "workspace number 8";
        "${cfg.config.modifier}+9" = "workspace number 9";
        "${cfg.config.modifier}+0" = "workspace number 10";

        "${cfg.config.modifier}+Shift+1" = "move container to workspace number 1";
        "${cfg.config.modifier}+Shift+2" = "move container to workspace number 2";
        "${cfg.config.modifier}+Shift+3" = "move container to workspace number 3";
        "${cfg.config.modifier}+Shift+4" = "move container to workspace number 4";
        "${cfg.config.modifier}+Shift+5" = "move container to workspace number 5";
        "${cfg.config.modifier}+Shift+6" = "move container to workspace number 6";
        "${cfg.config.modifier}+Shift+7" = "move container to workspace number 7";
        "${cfg.config.modifier}+Shift+8" = "move container to workspace number 8";
        "${cfg.config.modifier}+Shift+9" = "move container to workspace number 9";
        "${cfg.config.modifier}+Shift+0" = "move container to workspace number 10";

        "${cfg.config.modifier}+Shift+c" = "reload";
        "${cfg.config.modifier}+Shift+r" = "restart";
        "${cfg.config.modifier}+Shift+e" =
          "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'";

        "${cfg.config.modifier}+r" = "mode resize";
      };
      bars = [
        {
          position = "top";
          #statusCommand = "${pkgs.polybar}/bin/polybar";
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
          colors = {
            separator = "#666666";
            background = "#222222";
            statusline = "#dddddd";
          };
        }
      ];
      terminal = "alacritty";
      menu = "rofi -show drun -run-shell-command '{terminal} -e zsh -ic \"{cmd} && read\"'";
    };
    extraConfig = ''
      exec --no-startup-id feh --bg-scale /home/heph/Pictures/wool-linux.png
      default_border pixel 1
    '';
  };

  services.polybar = {
    enable = false;
    script = ''
      polybar top &
    '';
  };

  programs.i3status-rust = {
    enable = false;
    bars = {
      top = {
        theme = "solarized-dark";
        blocks = [
          {
            block = "sound";
            click = [
              {
                button = "left";
                cmd = "pavucontrol";
              }
            ];
          }
          {
            block = "cpu";
            info_cpu = 20;
            warning_cpu = 50;
            critical_cpu = 90;
          }
          {
            block = "time";
            interval = 5;
            format = " $timestamp.datetime(f:'%a %d/%m %R') ";
          }
          {
            block = "custom";
            command = "echo 'uf0ac ' `curl bot.whatismyipaddress.com`";
            interval = 60;
          }
          {
            block = "custom";
            command = "sed 's/  //' <(curl 'https://wttr.in/Nova_Milanese?format=1' -s)";
            interval = 600;
          }
        ];
      };
    };
  };
}
