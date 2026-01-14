{ config, pkgs, ... }:

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
      host = "radarr.pochi.casa";
      upstream = "localhost:7878";
    }
    {
      host = "usenet.pochi.casa";
      upstream = "localhost:8080";
    }
    {
      host = "paperless.pochi.casa";
      upstream = "localhost:28981";
    }
    {
      host = "jelly.pochi.casa";
      upstream = "localhost:8096";
    }
    {
      host = "jellyseerr.pochi.casa";
      upstream = "localhost:5055";
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
            resolvers 1.1.1.1 8.8.8.8
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
  services.caddy.package = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
    hash = "sha256-4qUWhrv3/8BtNCi48kk4ZvbMckh/cGRL7k+MFvXKbTw=";
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  age.secrets.cloudflare = {
    file = ../../secrets/cloudflare_api_token.age;
    mode = "640";
    owner = "caddy";
    group = "caddy";
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.age.secrets.cloudflare.path
  ];
}
