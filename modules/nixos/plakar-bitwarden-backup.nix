{ ... }:
{
  infra.modules.nixos.plakar-bitwarden-backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.plakar-bitwarden-backup;

      backupCommand = lib.escapeShellArgs [
        (lib.getExe cfg.package)
        "-stdio"
        "at"
        cfg.repository
        "backup"
        "-name"
        "bitwarden"
        "-tag"
        "bitwarden,scheduled"
        "-o"
        "session_env=PLAKAR_BITWARDEN_SESSION"
        "-o"
        "data_dir=${cfg.dataDir}"
        cfg.location
      ];

      backupScript = pkgs.writeShellScript "plakar-bitwarden-backup" ''
        set -euo pipefail
        export PLAKAR_PASSPHRASE="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/repository-passphrase")"
        export PLAKAR_BITWARDEN_SESSION="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/session")"
        exec ${backupCommand}
      '';
    in
    {
      options.services.plakar-bitwarden-backup = {
        enable = lib.mkEnableOption "scheduled Plakar backups of Bitwarden";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.plakar.withPlugins (plugins: [ plugins.bitwarden ]);
          defaultText = lib.literalExpression "pkgs.plakar.withPlugins (plugins: [ plugins.bitwarden ])";
          description = "Plakar package containing the Bitwarden plugin.";
        };

        repository = lib.mkOption {
          type = lib.types.str;
          description = "Existing Plakar repository used for snapshots.";
        };

        location = lib.mkOption {
          type = lib.types.str;
          description = "Bitwarden connector location.";
        };

        dataDir = lib.mkOption {
          type = lib.types.str;
          description = "Persistent Bitwarden CLI state directory.";
        };

        sessionFile = lib.mkOption {
          type = lib.types.path;
          description = "File containing the BW_SESSION session key.";
        };

        passphraseFile = lib.mkOption {
          type = lib.types.path;
          description = "File containing the Plakar repository passphrase.";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "Local user running the backup.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "Local group running the backup.";
        };

        onCalendar = lib.mkOption {
          type = lib.types.str;
          default = "weekly";
          description = "Systemd calendar expression for the backup timer.";
        };

        randomizedDelaySec = lib.mkOption {
          type = lib.types.str;
          default = "1h";
          description = "Maximum randomized delay applied to each run.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = builtins.hasAttr cfg.user config.users.users;
            message = "services.plakar-bitwarden-backup.user must name a configured local user";
          }
        ];

        systemd.services.plakar-bitwarden-backup = {
          description = "Back up Bitwarden vault items with Plakar";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment.HOME = config.users.users.${cfg.user}.home;
          path = [ pkgs.bitwarden-cli ];

          serviceConfig = {
            Type = "oneshot";
            User = cfg.user;
            Group = cfg.group;
            UMask = "0077";
            LoadCredential = [
              "repository-passphrase:${cfg.passphraseFile}"
              "session:${cfg.sessionFile}"
            ];
            ExecStart = backupScript;
          };
        };

        systemd.timers.plakar-bitwarden-backup = {
          description = "Weekly Bitwarden backup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.onCalendar;
            Persistent = true;
            RandomizedDelaySec = cfg.randomizedDelaySec;
          };
        };
      };
    };
}
