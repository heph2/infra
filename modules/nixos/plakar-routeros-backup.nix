{ ... }:
{
  infra.modules.nixos.plakar-routeros-backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.plakar-routeros-backup;

      backupCommand =
        mode:
        lib.escapeShellArgs [
          (lib.getExe cfg.package)
          "-stdio"
          "at"
          cfg.repository
          "backup"
          "-name"
          "routeros-${mode}"
          "-tag"
          "routeros,${mode}"
          "-o"
          "private_key=${cfg.privateKeyFile}"
          "routeros+${mode}://${cfg.routerUser}@${cfg.routerAddress}"
        ];

      backupScript = pkgs.writeShellScript "plakar-routeros-backup" ''
        set -euo pipefail
        export PLAKAR_PASSPHRASE="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/repository-passphrase")"
        ${lib.concatMapStringsSep "\n" backupCommand cfg.modes}
      '';
    in
    {
      options.services.plakar-routeros-backup = {
        enable = lib.mkEnableOption "scheduled Plakar backups of RouterOS";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.plakar.withPlugins (plugins: [ plugins.routeros ]);
          defaultText = lib.literalExpression "pkgs.plakar.withPlugins (plugins: [ plugins.routeros ])";
          description = "Plakar package containing the RouterOS plugin.";
        };

        repository = lib.mkOption {
          type = lib.types.str;
          description = "Existing Plakar repository used for the snapshots.";
        };

        routerAddress = lib.mkOption {
          type = lib.types.str;
          description = "RouterOS hostname or IP address.";
        };

        routerUser = lib.mkOption {
          type = lib.types.str;
          description = "RouterOS SSH user.";
        };

        privateKeyFile = lib.mkOption {
          type = lib.types.str;
          description = "SSH private key readable by the service user.";
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

        modes = lib.mkOption {
          type = lib.types.listOf (
            lib.types.enum [
              "export"
              "backup"
            ]
          );
          default = [ "export" ];
          description = "RouterOS backup formats to collect sequentially.";
        };

        onCalendar = lib.mkOption {
          type = lib.types.str;
          default = "weekly";
          description = "systemd calendar expression for the backup timer.";
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
            assertion = cfg.modes != [ ];
            message = "services.plakar-routeros-backup.modes must not be empty";
          }
          {
            assertion = builtins.hasAttr cfg.user config.users.users;
            message = "services.plakar-routeros-backup.user must name a configured local user";
          }
        ];

        systemd.services.plakar-routeros-backup = {
          description = "Back up RouterOS configuration with Plakar";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment.HOME = config.users.users.${cfg.user}.home;

          serviceConfig = {
            Type = "oneshot";
            User = cfg.user;
            Group = cfg.group;
            UMask = "0077";
            LoadCredential = [ "repository-passphrase:${cfg.passphraseFile}" ];
            ExecStart = backupScript;
          };
        };

        systemd.timers.plakar-routeros-backup = {
          description = "Weekly RouterOS backup";
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
