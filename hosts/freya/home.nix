{
  config,
  pkgs,
  agenix,
  stardew-modding,
  inputs,
  ...
}:

let
  cfg = config.xsession.windowManager.i3;
  obscuraPackage = inputs.obscura.packages.${pkgs.stdenv.hostPlatform.system}.obscura-browser-bin;
in
{
  imports = [
    agenix.homeManagerModules.default
    stardew-modding.homeManagerModules.default
    inputs.voxtype.homeManagerModules.default
    #    ../../modules/graphical/firefox/default.nix
  ];

  home.stateVersion = "24.05";

  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
  };

  programs.voxtype = {
    enable = true;
    # Vulkan build = GPU transcription on the RX 9060 XT (whisper.cpp gpu-vulkan feature).
    package = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.vulkan;
    model.name = "base.en";
    service.enable = true;
    settings.hotkey = {
      enabled = true;
      key = "RIGHTALT";
    };
    # ponytail: gpu_device left unset (Vulkan device 0). If it picks the Raphael
    # iGPU instead of the dGPU, set settings.whisper.gpu_device to the right index
    # from `vulkaninfo --summary`.
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

  age = {
    identityPaths = [ "/home/heph/.ssh/sekai_ed" ];
    secrets.vja-api-token = {
      file = ../../secrets/vja-api-token.age;
      path = "${config.home.homeDirectory}/.config/vja/token.json";
    };
  };

  home.file.".config/vja/config.rc".text = ''
    [application]
    frontend_url=https://vikunja.pochi.casa/
    api_url=https://vikunja.pochi.casa/api/v1
  '';

  home.file.".config/wezterm/agincourttriptych.jpg".source =
    ../../assets/agincourttriptych-center-donato-3000-2560x1474.jpg;

  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require("wezterm")

      local config = wezterm.config_builder()

      config.color_scheme = "rose-pine-moon"
      config.window_background_image = "${config.home.homeDirectory}/.config/wezterm/agincourttriptych.jpg"
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
      wl-clipboard
      mpv
      anydesk
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
      obscuraPackage
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
      vja # Vikunja Cli
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
      cmake
      gcc
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

  programs.ssh.matchBlocks = {
    "*".addKeysToAgent = "yes";
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
    remarkable = {
      port = 22;
      hostname = "10.11.99.1";
      user = "root";
      identityFile = "/home/heph/.ssh/test-id_rsa";
    };
    pixie = {
      hostname = "pixie";
      user = "root";
    };
  };

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

  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd z" ];
    };
    yazi.shellWrapperName = "yy";
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

  programs.helix.settings.keys.normal.C-y = {
    y = ":sh zellij run -n Yazi -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh open";
    v = ":sh zellij run -n Yazi -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh vsplit";
    h = ":sh zellij run -n Yazi -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh hsplit";
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
  services.blueman-applet.enable = true;
  services.flameshot.enable = true;
  services.unclutter.enable = true;
  services.emacs.enable = true;

  programs.firefox.profiles.default.settings = {
    "media.ffmpeg.vaapi.enabled" = true;
    "media.rdd-vpx.enabled" = true;
  };

  systemd.user.services.obscura = {
    Unit = {
      Description = "Obscura headless browser";
      After = [ "network.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${obscuraPackage}/bin/obscura serve --host 127.0.0.1 --port 9222 --storage-dir ${config.xdg.stateHome}/obscura";
      Restart = "on-failure";
      RestartSec = 5;
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

  programs.zsh.shellAliases = {
    a = "amused";
    d = "docker";
    mg = "mg -n";
    zzz = "shutdown now";
    k = "kubectl";
    ks = "kubectl config get-contexts |  awk 'NR>1 { print $2 }' | fzf | xargs kubectl config use-context";
    update = "sudo nixos-rebuild switch";
    game = "sudo virsh start win11-2";
  };

  programs.git = {
    signing.format = "openpgp";
    settings = {
      aliases.month-exp = " hledger balance expenses --period thismonth -f ~/Documents/finance/2026.journal";
      filter.annex = {
        clean = "git-annex smudge --clean -- %f";
        smudge = "git-annex smudge -- %f";
        process = "git-annex filter-process";
        required = true;
      };
    };
  };

  programs.notmuch.enable = true;
  programs.aerc = {
    enable = true;
    extraConfig = {
      general.unsafe-accounts-conf = true;
      filters."text/html" = "w3m -T text/html";
    };
    extraAccounts.Personal = {
      source = "maildir://~/Maildir/personal";
      outgoing = "${pkgs.msmtp}/bin/msmtp";
      default = "INBOX";
      from = "Marco Bauce <me@mbauce.com>";
      copy-to = "Sent";
      check-mail-cmd = "mbsync personal";
      check-mail = "1m";
    };
  };
  accounts.email.accounts.work = {
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
