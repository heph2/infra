{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.xsession.windowManager.i3;
in
{
  imports = [
    #    ../../modules/graphical/firefox/default.nix
  ];

  home.username = "heph";
  home.homeDirectory = "/home/heph";
  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;
  programs.home-manager.enable = true;
  home.packages =
    with pkgs;
    [
      (pkgs.emacsWithPackagesFromUsePackage {
        config = ./emacs.el;
        defaultInitFile = true;
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
      (pkgs.callPackage ../../pkgs/amused.nix { })
      # (pkgs.callPackage ./pkgs/thorium.nix { })
      # zen-browser.packages."${system}".default
      mpv
      nix-output-monitor
      brave
      transmission_4-qt
      libreoffice
      kdePackages.okular
      ranger
      gnumake
      xclip
      jq
      pnpm_10
      jless
      feh
      trayer
      chiaki-ng
      light
      xscreensaver
      reaper
      nautilus
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
      wezterm
      devenv
      xfce.xfce4-power-manager
      anki
      gh
      logisim-evolution
      chromium
      floorp
      age
      age-plugin-yubikey
      passage
      yubikey-manager
      yubikey-touch-detector
      yubikey-agent
      libu2f-host
      pam_u2f
    ]
    ++ (with haskellPackages; [
      ghcid
      xmobar
      yeganesh
    ]);

  programs.ssh = {
    enable = true;
    matchBlocks = {
      zima = {
        port = 22;
        hostname = "192.168.1.30";
        user = "root";
        identityFile = "/home/heph/.ssh/sekai_ed";
      };
      hermes = {
        port = 22;
        hostname = "135.181.85.238";
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
        hostname = "192.168.1.24";
        user = "root";
        identityFile = "/home/heph/.ssh/id_rsa_remarkable";
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

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    extraConfig = ''
      set-option -g mouse on
    '';
  };

  programs.nushell = {
    enable = true;
  };

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    bash.enable = true;
  };

  programs.yazi = {
    enable = true;
  };

  programs.qutebrowser = {
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
    };
    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
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

  programs.k9s.enable = true;

  # systemd.user.services.mpris-proxy = {
  #   description = "Mpris proxy";
  #   after = [ "network.target" "sound.target" ];
  #   wantedBy = [ "default.target" ];
  #   serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  # };

  programs.zsh = {
    enable = true;
    initExtra = "source ~/.p10k.zsh";
    shellAliases = {
      ll = "ls -l";
      mg = "mg -n";
      zzz = "shutdown now";
      k = "kubectl";
      k-switch = "kubectl config get-contexts |  awk 'NR>1 { print $2 }' | fzf | xargs kubectl config use-context";
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
    aliases = {
      gp = "add -p";
      co = "checkout";
      s = "switch";
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
    userEmail = "srht@mrkeebs.eu";
    userName = "heph";
  };

  programs.mbsync.enable = true;
  programs.msmtp = {
    enable = true;
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
      passwordCommand = "passage show me@mbauce.com";
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
    enable = true;
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
    enable = true;
    script = ''
      polybar top &
    '';
  };

  programs.i3status-rust = {
    enable = true;
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
