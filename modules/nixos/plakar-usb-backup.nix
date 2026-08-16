{ ... }:
{
  infra.modules.nixos.plakar-usb-backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.plakar-usb-backup;
      enabledBackups = lib.filterAttrs (_: backup: backup.enable) cfg;

      backupCommand =
        backup:
        lib.escapeShellArgs (
          [
            (lib.getExe backup.package)
            "-stdio"
            "at"
            backup.repository
            "backup"
            "-name"
            backup.snapshotName
          ]
          ++ lib.optionals (backup.tags != [ ]) [
            "-tag"
            (lib.concatStringsSep "," backup.tags)
          ]
          ++ lib.concatMap (option: [
            "-o"
            "${option}=${backup.connectorOptions.${option}}"
          ]) (builtins.attrNames backup.connectorOptions)
          ++ backup.extraArguments
          ++ [ backup.location ]
        );

      waitScript =
        backup:
        lib.optionalString (backup.readiness.host != null) ''
          ready=false
          for (( elapsed = 0; elapsed < ${toString backup.readiness.timeoutSec}; elapsed++ )); do
            if ${pkgs.netcat-openbsd}/bin/nc -z -w 1 ${lib.escapeShellArg backup.readiness.host} ${toString backup.readiness.port}; then
              ready=true
              break
            fi
            ${pkgs.coreutils}/bin/sleep 1
          done
          if [[ "$ready" != true ]]; then
            echo "${backup.readiness.host}:${toString backup.readiness.port} did not become available" >&2
            exit 1
          fi
        '';

      mkService =
        name: backup:
        lib.nameValuePair "plakar-${name}-backup" {
          description = "Back up ${name} when connected over USB";
          after = lib.optional (backup.readiness.host != null) "NetworkManager.service";
          environment.HOME = config.users.users.${backup.user}.home;
          path = backup.runtimePackages;
          script = ''
            set -euo pipefail
            ${waitScript backup}
            export PLAKAR_PASSPHRASE="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/repository-passphrase")"
            ${backupCommand backup}
          '';
          serviceConfig = {
            Type = "oneshot";
            User = backup.user;
            Group = backup.group;
            UMask = "0077";
            LoadCredential = [
              "repository-passphrase:${backup.passphraseFile}"
            ];
          };
        };

      udevRule =
        name: backup:
        ''ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="${lib.toLower backup.usbVendorId}", ATTR{idProduct}=="${lib.toLower backup.usbProductId}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="plakar-${name}-backup.service"'';
    in
    {
      options.services.plakar-usb-backup = lib.mkOption {
        default = { };
        description = "USB-triggered Plakar backup jobs.";
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                enable = lib.mkEnableOption "the ${name} USB-triggered Plakar backup";

                package = lib.mkOption {
                  type = lib.types.package;
                  default = pkgs.plakar;
                  description = "Plakar package containing the required integration.";
                };

                repository = lib.mkOption {
                  type = lib.types.str;
                  description = "Existing Plakar repository used for snapshots.";
                };

                location = lib.mkOption {
                  type = lib.types.str;
                  description = "Connector location passed to Plakar.";
                };

                snapshotName = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = "Name assigned to each snapshot.";
                };

                tags = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [
                    name
                    "usb"
                  ];
                  description = "Tags assigned to each snapshot.";
                };

                connectorOptions = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                  description = "Connector options passed as Plakar -o arguments.";
                };

                extraArguments = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Additional arguments inserted before the connector location.";
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

                usbVendorId = lib.mkOption {
                  type = lib.types.strMatching "[0-9A-Fa-f]{4}";
                  description = "USB vendor ID matched by udev.";
                };

                usbProductId = lib.mkOption {
                  type = lib.types.strMatching "[0-9A-Fa-f]{4}";
                  description = "USB product ID matched by udev.";
                };

                readiness = lib.mkOption {
                  default = { };
                  description = "Optional TCP endpoint that must become reachable before backup.";
                  type = lib.types.submodule {
                    options = {
                      host = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Host to poll, or null to start immediately.";
                      };

                      port = lib.mkOption {
                        type = lib.types.port;
                        default = 22;
                        description = "TCP port to poll.";
                      };

                      timeoutSec = lib.mkOption {
                        type = lib.types.ints.positive;
                        default = 30;
                        description = "Maximum time to wait for the endpoint.";
                      };
                    };
                  };
                };
              };
            }
          )
        );
      };

      config = lib.mkIf (enabledBackups != { }) {
        assertions = lib.mapAttrsToList (_: backup: {
          assertion = builtins.hasAttr backup.user config.users.users;
          message = "services.plakar-usb-backup user must name a configured local user";
        }) enabledBackups;

        services.udev.extraRules = lib.concatStringsSep "\n" (lib.mapAttrsToList udevRule enabledBackups);

        systemd.services = lib.mapAttrs' mkService enabledBackups;
      };
    };
}
