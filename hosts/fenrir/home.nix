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
    ansible-good-practices =
      inputs.claude-ansible-skills + "/ansible-good-practices/skills/ansible-good-practices";
    ansible-new-role = inputs.claude-ansible-skills + "/ansible-new-role/skills/ansible-new-role";
    ansible-new-collection =
      inputs.claude-ansible-skills + "/ansible-new-collection/skills/ansible-new-collection";
    ansible-new-ee = inputs.claude-ansible-skills + "/ansible-new-ee/skills/ansible-new-ee";
    ansible-new-molecule =
      inputs.claude-ansible-skills + "/ansible-new-molecule/skills/ansible-new-molecule";
    ansible-docs = inputs.claude-ansible-skills + "/ansible-docs/skills/ansible-docs";
    ansible-zen = inputs.claude-ansible-skills + "/ansible-zen/skills/ansible-zen";
    aws-best-practices = awsBestPracticesSkill;
    nixos-host-workflow = ../../skills/nixos-host-workflow;
    hledger-finance = ../../skills/hledger-finance;
    vikunja = ../../skills/vikunja;
  };
in
{
  imports = [
    agenix.homeManagerModules.default
    inputs.noctalia.homeModules.default
    inputs.pi.homeModules.default
  ];

  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "hx";
  };

  home.file.".agent-browser/config.json".text = builtins.toJSON {
    cdp = "9222";
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
        "vikunja.pochi.casa"
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

  home.file.".pi/agent/extensions/pi-tool-display/config.json".text = builtins.toJSON {
    # pi-sandbox already overrides bash for sandboxing; avoid dueling
    # tool-ownership registration between the two extensions.
    registerToolOverrides.bash = false;
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
        # 0.6.1 monkey-patched tui.doRender; pi 0.84.0 proxies it -> infinite
        # recursion -> "Maximum call stack size exceeded" on TUI start.
        # 0.9.0 dropped the extension-owned fixed editor.
        "npm:pi-powerline-footer@0.12.1"
        "npm:@quintinshaw/pi-dynamic-workflows@2.11.0"
        "npm:@victor-software-house/pi-agent-browser"

        # Reuse the local Claude Code OAuth session as a pi provider.
        # Risk accepted interactively: this third-party extension uses non-public Anthropic protocol details.
        "npm:@cgaravitoq/pi-claude-code-auth@2.3.0"
      ];
    };
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
