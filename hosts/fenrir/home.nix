{ config, pkgs, lib, agenix, firefox-addons, inputs, ... }:

let
  noctalia = cmd:
    [ "noctalia-shell" "ipc" "call" ] ++ (pkgs.lib.splitString " " cmd);
in {
  imports =
    [ agenix.homeManagerModules.default inputs.noctalia.homeModules.default ];

  home.username = "heph";
  home.homeDirectory = "/home/heph";
  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;
  programs.home-manager.enable = true;

  home.sessionVariables = { EDITOR = "hx"; };

  home.packages = with pkgs; [
    mpv
    thunar
    w3m
    kdePackages.okular
    hledger
    jujutsu
    lazygit
    vesktop
    brave
    speedtest-cli
    ranger
    gnumake
    jq
    jless
    feh
    playerctl
    nautilus
    ncdu
    unzip
    telegram-desktop
    pwvucontrol
    wireplumber
    gh
    delta
    nix-output-monitor
    rclone
    imagemagick
    python3
    nodejs
    pnpm_10
    devenv
    ffmpeg
    nmap
    psmisc
    xclip
    alsa-utils
    rclone
  ];

  programs.ssh = {
    enable = true;
    matchBlocks = {
      freya = {
        port = 22;
        hostname = "192.168.0.102";
        user = "heph";
        identityFile = "/home/heph/.ssh/sekai_ed";
      };
      zima = {
        port = 22;
        hostname = "192.168.0.105";
        user = "root";
        identityFile = "/home/heph/.ssh/sekai_ed";
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
      sauron = {
        port = 22;
        hostname = "192.168.0.106";
        user = "root";
        identityFile = "/home/heph/.ssh/sekai_ed";
      };
      github = {
        port = 22;
        hostname = "github.com";
        user = "git";
        identityFile = "/home/heph/.ssh/sr-ht_rsa";
      };
    };
  };

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    extraConfig = ''
      set-option -g mouse on
      bind-key h split-window -v
      bind-key v split-window -h
    '';
  };

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    bash.enable = true;
  };

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };

  programs.zellij = { enable = true; };

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      window-decoration = "none";
      font-size = 13;
      font-family = "Hack Nerd Font";
      theme = "catppuccin-mocha";
      unfocused-split-opacity = 0.96;
      font-feature = [ "-liga" "-dlig" "-calt" ];
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
    };
    languages.language = [{
      name = "nix";
      auto-format = true;
      formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
    }];
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };

  programs.fzf = { enable = true; };

  programs.htop.enable = true;
  programs.zathura.enable = true;
  programs.k9s.enable = true;

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

  programs.noctalia-shell = {
    enable = true;
    package =
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        calendarSupport = true;
      };
    settings = {
      bar = {
        density = "compact";
        position = "top";
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            { id = "ActiveWindow"; }
          ];
          center = [{
            id = "Workspace";
            hideUnoccupied = false;
            labelMode = "none";
          }];
          right = [
            {
              id = "Battery";
              alwaysShowPercentage = false;
              warningThreshold = 30;
            }
            { id = "Volume"; }
            { id = "Brightness"; }
            {
              id = "Clock";
              formatHorizontal = "HH:mm";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
      colorSchemes = {
        predefinedScheme = "Noctalia (default)";
        darkMode = true;
      };
      general = {
        avatarImage = "${config.home.homeDirectory}/.face";
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = true;
        name = "Nova Milanese, Italy";
      };
    };
  };

  programs.niri = {
    settings = {
      input = {
        keyboard = { xkb.layout = "us"; };
        touchpad = {
          tap = true;
          natural-scroll = true;
          click-method = "clickfinger";
        };
        mouse = { natural-scroll = true; };
      };

      spawn-at-startup = [{ command = [ "noctalia-shell" ]; }];

      binds = with config.lib.niri.actions;
        let mod = "Super";
        in {
          "${mod}+Return".action.spawn = [ "ghostty" ];
          "${mod}+Space".action.spawn = noctalia "launcher toggle";
          "${mod}+Shift+Q".action = close-window;
          "${mod}+Shift+Escape".action.spawn = noctalia "lockScreen lock";

          "${mod}+H".action = focus-column-left;
          "${mod}+J".action = focus-window-down;
          "${mod}+K".action = focus-window-up;
          "${mod}+L".action = focus-column-right;

          "${mod}+Shift+H".action = move-column-left;
          "${mod}+Shift+J".action = move-window-down;
          "${mod}+Shift+K".action = move-window-up;
          "${mod}+Shift+L".action = move-column-right;

          "${mod}+F".action = fullscreen-window;
          "${mod}+V".action = toggle-window-floating;

          "${mod}+1".action = focus-workspace 1;
          "${mod}+2".action = focus-workspace 2;
          "${mod}+3".action = focus-workspace 3;
          "${mod}+4".action = focus-workspace 4;
          "${mod}+5".action = focus-workspace 5;
          "${mod}+6".action = focus-workspace 6;
          "${mod}+7".action = focus-workspace 7;
          "${mod}+8".action = focus-workspace 8;
          "${mod}+9".action = focus-workspace 9;

          "${mod}+Shift+1".action.move-column-to-workspace = 1;
          "${mod}+Shift+2".action.move-column-to-workspace = 2;
          "${mod}+Shift+3".action.move-column-to-workspace = 3;
          "${mod}+Shift+4".action.move-column-to-workspace = 4;
          "${mod}+Shift+5".action.move-column-to-workspace = 5;
          "${mod}+Shift+6".action.move-column-to-workspace = 6;
          "${mod}+Shift+7".action.move-column-to-workspace = 7;
          "${mod}+Shift+8".action.move-column-to-workspace = 8;
          "${mod}+Shift+9".action.move-column-to-workspace = 9;

          "${mod}+Comma".action = consume-window-into-column;
          "${mod}+Period".action = expel-window-from-column;

          "${mod}+R".action = switch-preset-column-width;
          "${mod}+Shift+R".action = reset-window-height;
          "${mod}+Minus".action = set-column-width "-10%";
          "${mod}+Equal".action = set-column-width "+10%";

          "${mod}+Shift+E".action = quit;

          "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
          "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
          "XF86AudioMute".action.spawn = noctalia "volume muteOutput";
          "XF86AudioPlay".action.spawn = [ "playerctl" "play" ];
          "XF86AudioPause".action.spawn = [ "playerctl" "pause" ];
          "XF86AudioNext".action.spawn = [ "playerctl" "next" ];
          "XF86AudioPrev".action.spawn = [ "playerctl" "prev" ];
          "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
          "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";
        };

      environment = {
        DISPLAY = ":0";
        XDG_SESSION_TYPE = "wayland";
      };

      layout = {
        gaps = 8;
        preset-column-widths = [
          { proportion = 0.333333; }
          { proportion = 0.5; }
          { proportion = 0.666667; }
        ];
        default-column-width = { proportion = 0.5; };
        center-focused-column = "never";
        focus-ring = { enable = false; };
        border = {
          enable = true;
          width = 1;
          active.color = "#7c3aed";
          inactive.color = "#333333";
        };
      };

      prefer-no-csd = true;

      screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png";

      animations = {
        enable = true;
        slowdown = 1.0;
      };
    };
  };

  programs.zsh = {
    enable = true;
    initContent = "source ~/.p10k.zsh";
    shellAliases = {
      ll = "ls -l";
      lz = "lazygit";
      update = "sudo nixos-rebuild switch --flake .#fenrir";
    };
    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; }
        {
          name = "romkatv/powerlevel10k";
          tags = [ "as:theme" "depth:1" ];
        }
      ];
    };
  };

  programs.git = {
    enable = true;
    settings = {
      aliases = {
        gp = "add -p";
        co = "checkout";
        s = "switch";
        st = "status";
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
    };
    userEmail = "srht@mrkeebs.eu";
    userName = "heph";
  };

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
      extensions.packages = with firefox-addons.packages.${pkgs.system}; [
        ublock-origin
        bitwarden
        user-agent-string-switcher
        multi-account-containers
        kagi-search
      ];
      settings = {
        "sidebar.verticalTabs" = true;
        "sidebar.revamp" = true;
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
        "gfx.webrender.all" = true;
        "layers.acceleration.force-enabled" = true;
        "browser.tabs.drawInTitlebar" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "general.smoothScroll" = true;
        "browser.sessionstore.resume_from_crash" = true;
        "browser.tabs.tabmanager.enabled" = false;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "widget.use-xdg-desktop-portal.mime-handler" = 1;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
  };
}
