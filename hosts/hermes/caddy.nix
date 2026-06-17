{ pkgs, ... }:

let
  vhosts = [
    {
      host = "auth.pochi.casa";
      upstream = "sauron.pochi.casa:1411";
    }
    {
      host = "budget.pochi.casa";
      upstream = "zima.pochi.casa:5006";
    }
    {
      host = "trippiamo.mbauce.com";
      upstream = "tyr.pochi.casa:6767";
    }
  ];

  caddyFile = pkgs.writeText "Caddyfile" (
    ''
      {
        email infra@mbauce.com
      }
    ''
    + (builtins.concatStringsSep "\n\n" (
      map (v: ''
        ${v.host} {
          encode zstd gzip
          reverse_proxy ${v.upstream}
          ${v.extra or ""}
        }
      '') vhosts
    ))
  );
in
{
  services.caddy.enable = true;
  services.caddy.configFile = caddyFile;
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
