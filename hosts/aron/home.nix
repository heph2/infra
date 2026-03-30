{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
let
  home = "/Users/marco";
in
{
  imports = [
    #./fish.nix
    ./home-pkgs.nix
    inputs.paneru.homeModules.paneru
  ];

  home.stateVersion = "22.05";

  home.sessionVariables = {
    EDITOR = "hx";
    LIMA_HOME = "$HOME/env/colima";
    LEDGER_FILE = "~/env/finance/2026.journal";
    GRANTED_ALIAS_CONFIGURED = "true";
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
    #   imap.host = "pro2.mail.ovh.net";
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
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    mbsync.enable = true;
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
    htop.enable = true;
    msmtp.enable = true;
    # ghostty = {
    #   enable = true;
    #   enableZshIntegration = true;
    #   keybindings = {
    #      "global:ctrl+shift+e" = "toggle_quick_terminal";
    #   };
    #   settings = {
    #     font-size = 13;
    #     font-family = "JetBrainsMono Nerd Font";
    #     unfocused-split-opacity = 0.96;
    #     window-theme = "dark";
    #     macos-option-as-alt = true;
    #     theme = "catppuccin-frappe";
    #     font-feature = ["-liga" "-dlig" "-calt"];
    #   };
    # };
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        lz = "lazygit";
        mnew = "(mlist ~/Maildir/work/inbox; mlist ~/Maildir/personal/inbox) | mthread | msort -d -r | mseq -S";
        ll = "ls -l";
        update = "sudo nixos-rebuild switch";
        assume = "source ${pkgs.granted}/bin/assume";
        dw = "darwin-rebuild switch --flake '.#aron'";
        k = "kubectl";
        wgup = "sudo wg-quick up wg0";
        wgdown = "sudo wg-quick down wg0";
        ks = "kubectl config get-contexts |  awk 'NR>1 { print $2 }' | fzf | xargs kubectl config use-context";
      };
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "robbyrussell";
      };
    };
    zellij.enable = true;
    yazi.enable = true;
    opencode = {
      enable = true;
      enableMcpIntegration = true;
      agents = {
        devops-pm = ''
          # DevOps Team Project Manager

          You are a skilled project manager for a DevOps team consisting of 4 members (including the user). Your role is to help coordinate, plan, track, and manage the team's projects and tasks.

          ## Your Capabilities
          - Use Shortcut MCP to manage stories, epics, iterations, and labels
          - Use GitHub MCP to track repositories, issues, and pull requests
          - Create, update, and organize tasks and stories
          - Help with sprint planning and iteration management
          - Generate progress reports and summaries

          ## Team Context
          - 4-person DevOps team
          - Focus on infrastructure, automation, CI/CD, and cloud operations
          - Use Shortcut for project management
          - Use GitHub for code collaboration

          ## Guidelines
          - Always confirm before creating or modifying stories in Shortcut
          - Keep track of who is assigned to what
          - Help prioritize tasks based on team capacity
          - Suggest ways to improve team workflow
          - Provide clear summaries of project status when asked
          - Use labels to categorize work (infrastructure, automation, bug, feature, etc.)
        '';
      };
    };
    mcp = {
      enable = true;
      servers = {
        shortcut = {
          command = "npx";
          args = [
            "-y"
            "@shortcut/mcp@latest"
          ];
        };
        context7 = {
          command = "npx";
          args = [
            "-y"
            "@upstash/context7-mcp"
          ];
        };
        filesystem = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "${home}/code"
          ];
        };
      };
    };
    opencode.settings = {
      mcp = {
        github = {
          type = "remote";
          url = "https://api.githubcopilot.com/mcp/";
        };
        notion = {
          type = "remote";
          url = "https://mcp.notion.com/mcp";
        };
      };
    };
    yazi.shellWrapperName = "y";
    atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings.sync_address = "http://192.168.1.30:8888";
    };
    tmux = {
      enable = true;
      shell = "/etc/profiles/per-user/marco/bin/fish";
      extraConfig = "setw -g mouse on";
    };
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };
    git = {
      enable = true;
      settings = {
        alias = {
          gp = "add -p";
          co = "checkout";
          s = "switch";
          st = "status";
        };
        core = {
          pager = "delta";
        };
        pull = {
          ff = "only";
        };
        interactive = {
          diffFilter = "delta --color-only";
        };
        delta = {
          navigate = true;
          light = false;
          side-by-side = true;
        };
        user = {
          email = "srht@mrkeebs.eu";
          name = "heph";
        };
      };
      ignores = [
        "AGENTS.md"
        "CLAUDE.md"
        ".claude"
      ];
    };
    # spicetify =
    #   let
    #     spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
    #   in
    #   {
    #     enable = true;
    #     enabledExtensions = with spicePkgs.extensions; [
    #       adblock
    #       hidePodcasts
    #       shuffle
    #     ];
    #     theme = spicePkgs.themes.catppuccin;
    #     colorScheme = "mocha";
    #   };
  };

  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    extraPackages = epkgs: [
      epkgs.nix-mode
      epkgs.nixfmt
      epkgs.vterm
      (epkgs.treesit-grammars.with-all-grammars)
    ];
    # extraConfig = builtins.readFile "/Users/marco/.emacs.d/init.el";
  };

  services.paneru = {
    enable = false;
    settings = {
      options = {
        preset_column_widths = [
          0.25
          0.33
          0.5
          0.66
          0.75
        ];
        animation_speed = 4000;
      };
      swipe = {
        gesture = {
          fingers_count = 4;
          direction = "Natural";
        };
      };
      bindings = {
        window_focus_west = "cmd - h";
        window_focus_east = "cmd - l";
        window_focus_north = "cmd - k";
        window_focus_south = "cmd - j";
        window_swap_west = "alt - h";
        window_swap_east = "alt - l";
        window_swap_first = "alt + shift - h";
        window_swap_last = "alt + shift - l";
        window_center = "alt - c";
        window_resize = "alt - r";
        window_fullwidth = "alt - f";
        window_manage = "ctrl + alt - t";
        window_stack = "alt - ]";
        window_unstack = "alt + shift - ]";
        quit = "ctrl + alt - q";
      };
    };
  };

  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        "freya" = {
          id = "7JOHCPW-KSI55U3-LA357ZI-R7DH2OT-OMRP7Y6-UZ3WVMX-BTU4XB2-5Q27XQ2";
        };
      };
      folders = {
        "Ledger" = {
          path = "${home}/env/finance";
          devices = [ "freya" ];
        };
        "Emacs" = {
          path = "${home}/.emacs.d";
          devices = [ "freya" ];
        };
      };
    };
  };
}
