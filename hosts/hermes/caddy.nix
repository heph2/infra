{ pkgs, ... }:

let
  vhosts = [
    {
      host = "auth.pochi.casa";
      upstream = "sauron.pochi.casa:1414";
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
          encoze zstd gzip
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
