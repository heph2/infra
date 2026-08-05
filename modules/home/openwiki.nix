{
  # OpenWiki is a per-user CLI (credentials, checkpoints and cron state live in
  # ~/.openwiki), so it ships as a home-manager module: the same unit works on
  # NixOS and darwin hosts.
  infra.modules.homeManager.openwiki =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.openwiki;
    in
    {
      options.programs.openwiki = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install the OpenWiki agent documentation CLI.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.callPackage ../../pkgs/openwiki/package.nix { };
          defaultText = lib.literalExpression "pkgs.callPackage ../../pkgs/openwiki/package.nix { }";
          description = "OpenWiki package to install.";
        };

        provider = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "anthropic";
          description = ''
            Value for OPENWIKI_PROVIDER. Null leaves provider selection to
            `openwiki auth <provider>` / the interactive picker.
          '';
        };

        modelId = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "claude-opus-5";
          description = "Value for OPENWIKI_MODEL_ID.";
        };

        disableTelemetry = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Set OPENWIKI_TELEMETRY_DISABLED, opting out of PostHog reporting.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        home.sessionVariables =
          lib.optionalAttrs (cfg.provider != null) { OPENWIKI_PROVIDER = cfg.provider; }
          // lib.optionalAttrs (cfg.modelId != null) { OPENWIKI_MODEL_ID = cfg.modelId; }
          // lib.optionalAttrs cfg.disableTelemetry { OPENWIKI_TELEMETRY_DISABLED = "1"; };
      };
    };
}
