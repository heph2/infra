{ config, pkgs, lib, ... }:
let
  domain = "grafana.pochi.casa";
  issuer = "https://auth.pochi.casa";
in {
  services.grafana = {
    enable = true;
    settings = {
      server = {
        root_url = "https://${domain}";
        domain = domain;
        http_port = 3000;
        http_addr = "127.0.0.1";
      };
      security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
    };
  };

  age.secrets.grafana_oidc_client_secret = {
    file = ../../secrets/grafana-oidc-client-secret.age;
    path = "/run/agenix/grafana-oidc";
    mode = "640";
    owner = "grafana";
    group = "grafana";
  };

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    encode zstd gzip
    tls {
      dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      resolvers 1.1.1.1 8.8.8.8
    }
    reverse_proxy 127.0.0.1:3000
  '';

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
