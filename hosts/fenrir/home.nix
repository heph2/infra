{
  config,
  pkgs,
  lib,
  agenix,
  firefox-addons,
  inputs,
  ...
}:
with lib;
let
  home = config.home.homeDirectory;
  noctalia =
    cmd:
    [
      "noctalia-shell"
      "ipc"
      "call"
    ]
    ++ (pkgs.lib.splitString " " cmd);
in
{
  imports = [
    agenix.homeManagerModules.default
    inputs.noctalia.homeModules.default
  ];

  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "hx";
  };

  home.packages = with pkgs; [
    mpv
    thunar
    w3m
    kdePackages.okular
    hledger
    jujutsu
    arcanechat-tui
    bind
    feishin # Jelly music player
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
    mblaze
    afew
  ];

  programs.ssh.matchBlocks.freya = {
    port = 22;
    hostname = "192.168.0.102";
    user = "heph";
    identityFile = "/home/heph/.ssh/sekai_ed";
  };

  programs.yazi.shellWrapperName = "y";

  programs.ghostty.settings = {
    font-size = 13;
    font-family = "Hack Nerd Font";
    unfocused-split-opacity = 0.96;
    font-feature = [
      "-liga"
      "-dlig"
      "-calt"
    ];
  };

  programs.helix = {
    languages.language = [
      {
        name = "gmpl";
        scope = "source.gmpl";
        file-types = [
          "mod"
          "gmpl"
        ];
        comment-tokens = [ "#" ];
        block-comment-tokens = {
          start = "/*";
          end = "*/";
        };
        indent = {
          tab-width = 4;
          unit = "    ";
        };
      }
    ];
    languages.grammar = [
      {
        name = "gmpl";
        source.path = inputs.tree-sitter-gmpl;
      }
    ];
  };

  xdg.configFile."helix/runtime/grammars/gmpl.so".source =
    "${inputs.tree-sitter-gmpl.packages.aarch64-linux.default}/parser";

  xdg.configFile."helix/runtime/queries/gmpl".source =
    "${inputs.tree-sitter-gmpl.packages.aarch64-linux.default}/queries";

  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
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
          center = [
            {
              id = "Workspace";
              hideUnoccupied = false;
              labelMode = "none";
            }
          ];
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
        keyboard = {
          xkb.layout = "us";
        };
        touchpad = {
          tap = true;
          natural-scroll = true;
          click-method = "clickfinger";
        };
        mouse = {
          natural-scroll = true;
        };
      };

      spawn-at-startup = [{ command = [ "noctalia-shell" ]; }];

      binds =
        with config.lib.niri.actions;
        let
          mod = "Super";
        in
        {
          "${mod}+Return".action.spawn = [ "ghostty" ];
          "${mod}+Space".action.spawn = noctalia "launcher toggle";
          "${mod}+Shift+Q".action = close-window;
          "${mod}+Shift+Escape".action.spawn = noctalia "lockScreen lock";
          "${mod}+Question".action = show-hotkey-overlay;

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
          "XF86AudioPlay".action.spawn = [
            "playerctl"
            "play"
          ];
          "XF86AudioPause".action.spawn = [
            "playerctl"
            "pause"
          ];
          "XF86AudioNext".action.spawn = [
            "playerctl"
            "next"
          ];
          "XF86AudioPrev".action.spawn = [
            "playerctl"
            "prev"
          ];
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
        default-column-width = {
          proportion = 0.5;
        };
        center-focused-column = "never";
        focus-ring = {
          enable = false;
        };
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

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake .#fenrir";

  programs.firefox.profiles.default.extensions.packages = [
    firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}.ipvfoo
  ];

  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        "freya" = {
          id = "7JOHCPW-KSI55U3-LA357ZI-R7DH2OT-OMRP7Y6-UZ3WVMX-BTU4XB2-5Q27XQ2";
        };
        "aron" = {
          id = "AJ5RD3I-H6AKBMI-J7MP7LC-METYTUB-YEQNZTQ-FJUUTPA-REJTL7O-BKPH5QD";
        };
        "timballo" = {
          id = "";
        };
        "fenrir" = {
          id = "GBWF7RI-6NQT6HM-P4W32LH-ARGB7Z6-44FNVUZ-57B4JBK-N5MT2UU-GLPS6AK";
        };
      };
      folders = {
        "Age" = {
          path = "${home}/.age";
          devices = [
            "freya"
            "aron"
            "timballo"
          ];
        };
        "Emacs" = {
          path = "${home}/.emacs.d";
          devices = [
            "freya"
            "aron"
            "timballo"
          ];
        };
        "Gnupg" = {
          path = "${home}/.gnupg";
          devices = [
            "freya"
            "aron"
            "timballo"
          ];
        };
        "Ledger" = {
          path = "${home}/Documents/finance";
          devices = [
            "freya"
            "aron"
            "timballo"
          ];
        };
      };
    };
  };
}
