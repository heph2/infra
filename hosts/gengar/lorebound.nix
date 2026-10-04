{ config, pkgs, ... }:
let
  compose = "${pkgs.docker-compose}/bin/docker-compose";
  composeFile = "/etc/lorebound/compose.yaml";
  environmentFile = "/var/lib/lorebound/.env";
  composeCommand = "${compose} --file ${composeFile} --env-file ${environmentFile}";
  startLorebound = pkgs.writeShellScript "start-lorebound" ''
    set -euo pipefail
    ${composeCommand} up --detach postgres redis
    ${composeCommand} run --rm backend pnpm exec medusa db:migrate
    ${composeCommand} up --detach backend
  '';
in
{
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

  systemd.tmpfiles.rules = [ "d /var/lib/lorebound 0700 root root -" ];

  systemd.services.lorebound-stack = {
    description = "Lorebound Medusa backend, PostgreSQL, and Redis containers";
    after = [
      "docker.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
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
