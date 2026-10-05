{ config, pkgs, ... }:
let
  compose = "${pkgs.docker-compose}/bin/docker-compose";
  composeFile = "/etc/lorebound/compose.yaml";
  environmentFile = config.age.secrets.lorebound-env.path;
  composeCommand = "${compose} --file ${composeFile} --env-file ${environmentFile}";
  startLorebound = pkgs.writeShellScript "start-lorebound" ''
    set -euo pipefail

    registryConfig="$(${pkgs.coreutils}/bin/mktemp -d /run/lorebound-docker-config.XXXXXX)"
    trap '${pkgs.coreutils}/bin/rm -rf "$registryConfig"' EXIT
    export DOCKER_CONFIG="$registryConfig"

    ghcrToken="$(${pkgs.gawk}/bin/awk -F= '$1 == "GHCR_TOKEN" { sub(/^[^=]*=/, ""); print; exit }' ${environmentFile})"
    if [ -z "$ghcrToken" ]; then
      echo "GHCR_TOKEN is missing from the agenix environment" >&2
      exit 1
    fi
    printf '%s' "$ghcrToken" | ${pkgs.docker}/bin/docker login ghcr.io --username heph2 --password-stdin
    unset ghcrToken

    ${composeCommand} up --detach postgres redis
    ${composeCommand} run --rm backend pnpm exec medusa db:migrate
    ${composeCommand} up --detach backend
  '';
in
{
  age.secrets.lorebound-env = {
    file = ../../secrets/gengar-lorebound-env.age;
    mode = "0400";
    owner = "root";
    group = "root";
  };

  virtualisation.docker.enable = true;
  environment.systemPackages = [ pkgs.docker-compose ];
  environment.etc."lorebound/compose.yaml".source = ./lorebound-compose.yaml;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    virtualHosts."api.lorebound.shop".extraConfig = ''
      reverse_proxy 127.0.0.1:9000
    '';
  };

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
  };

  systemd.services.lorebound-stack = {
    description = "Lorebound Medusa backend, PostgreSQL, and Redis containers";
    after = [
      "docker.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = environmentFile;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 0;
      ExecStart = startLorebound;
      ExecStop = "${compose} --file ${composeFile} --env-file ${environmentFile} stop backend";
    };
  };
}
