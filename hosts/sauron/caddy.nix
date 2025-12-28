{ pkgs, ... }:

let
  vhosts = [
    {
      host = "torrent.pochi.casa";
      upstream = "localhost:8088";
    }
    {
      host = "prowlarr.pochi.casa";
      upstream = "localhost:9696";
    }
    {
      host = "sonarr.pochi.casa";
      upstream = "localhost:8989";
    }
    {
      host = "usenet.pochi.casa";
      upstream = "localhost:8080";
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
          tls {
            dns cloudflare {env.CLOUDFLARE_API_TOKEN}
          }
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
  age.secrets.cloudflare = {
    file = ../../secrets/cloudflare_api_token.age;
    mode = "640";
  };
  
  systemd.services.caddy.environment = {
    CLOUDFLARE_API_TOKEN = config.age.secrets.cloudflare.path
  };
}
