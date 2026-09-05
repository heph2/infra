{ ... }:
{
  infra.modules.nixos.plakar-backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.plakarbackup;
      enabledJobs = lib.filterAttrs (_: job: job.enable) cfg.jobs;

      backupCommand =
        job:
        lib.escapeShellArgs (
          [
            (lib.getExe job.package)
            "-stdio"
            "at"
            job.repository
            "backup"
            "-name"
            job.snapshotName
          ]
          ++ lib.optionals (job.tags != [ ]) [
            "-tag"
            (lib.concatStringsSep "," job.tags)
          ]
          ++ lib.concatMap (pattern: [
            "-ignore"
            pattern
          ]) job.exclude
          ++ job.extraArguments
          ++ job.paths
        );

      backupScript = job: ''
        set -euo pipefail
        export PLAKAR_PASSPHRASE="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/repository-passphrase")"
        exec ${backupCommand job}
      '';

      mkService =
        name: job:
        lib.nameValuePair "plakarbackup-${name}" {
          description = "Back up ${name} with Plakar";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment.HOME = config.users.users.${job.user}.home;
          path = [ pkgs.openssh ] ++ job.runtimePackages;

          serviceConfig = {
            Type = "oneshot";
            User = job.user;
            Group = job.group;
            UMask = "0077";
            RequiresMountsFor = job.paths;
            LoadCredential = [ "repository-passphrase:${job.passphraseFile}" ];
          };
          script = backupScript job;
        };

      mkTimer =
        name: job:
        lib.nameValuePair "plakarbackup-${name}" {
          description = "Plakar backup timer for ${name}";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = job.startAt;
            Persistent = job.persistentTimer;
            RandomizedDelaySec = job.randomizedDelaySec;
          };
        };
    in
    {
      options.services.plakarbackup = {
        jobs = lib.mkOption {
          default = { };
          description = "Scheduled Plakar backup jobs.";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  enable = lib.mkEnableOption "the ${name} Plakar backup job";

                  package = lib.mkOption {
                    type = lib.types.package;
                    default = pkgs.plakar.withPlugins (plugins: [ plugins.sftp ]);
                    defaultText = lib.literalExpression "pkgs.plakar.withPlugins (plugins: [ plugins.sftp ])";
                    description = "Plakar package containing the required integrations.";
                  };

                  repository = lib.mkOption {
                    type = lib.types.str;
                    description = "Plakar repository URI used for snapshots.";
                  };

                  paths = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Paths to include in each snapshot.";
                  };

                  exclude = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Plakar ignore patterns.";
                  };

                  extraArguments = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Additional arguments passed to `plakar backup`.";
                  };

                  snapshotName = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "Name assigned to each snapshot.";
                  };

                  tags = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ name ];
                    description = "Tags assigned to each snapshot.";
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

                  runtimePackages = lib.mkOption {
                    type = lib.types.listOf lib.types.package;
                    default = [ ];
                    description = "Packages added to the backup service PATH.";
                  };

                  startAt = lib.mkOption {
                    type = lib.types.str;
                    default = "weekly";
                    description = "systemd calendar expression for the backup timer.";
                  };

                  persistentTimer = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Run a missed backup when the host comes back online.";
                  };

                  randomizedDelaySec = lib.mkOption {
                    type = lib.types.str;
                    default = "1h";
                    description = "Maximum randomized delay applied to each run.";
                  };
                };
              }
            )
          );
        };
      };

      config = lib.mkIf (enabledJobs != { }) {
        assertions = lib.concatLists (
          lib.mapAttrsToList (_name: job: [
            {
              assertion = job.paths != [ ];
              message = "enabled Plakar backup jobs must include at least one path";
            }
            {
              assertion = builtins.hasAttr job.user config.users.users;
              message = "Plakar backup user must name a configured local user";
            }
            {
              assertion = builtins.hasAttr job.group config.users.groups;
              message = "Plakar backup group must name a configured local group";
            }
          ]) enabledJobs
        );

        systemd.services = lib.mapAttrs' mkService enabledJobs;
        systemd.timers = lib.mapAttrs' mkTimer enabledJobs;
      };
    };
}
