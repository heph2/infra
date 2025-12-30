{
  config,
  pkgs,
  lib,
  ...
}:
let
  domain = "homebox.pochi.casa";
  issuer = "https://auth.pochi.casa";
in
{
  services.homebox = {
    enable = true;
    settings = {
      HBOX_MODE = "production";
      HBOX_OPTIONS_HOSTNAME = domain;
      HBOX_OPTIONS_ALLOW_LOCAL_LOGIN = "false";
      HBOX_OPTIONS_ALLOW_REGISTRATION = "true";
      HBOX_OPTIONS_TRUST_PROXY = "true";
      HBOX_OIDC_ENABLED = "true";
      HBOX_OIDC_ISSUER_URL = issuer;
      HBOX_OIDC_CLIENT_ID = "bf75c2a3-e27b-45a3-9898-12d5cbfd5932";
      HBOX_OIDC_SCOPE = "openid profile email";
    };
  };

  systemd.services.homebox = {
    serviceConfig.EnvironmentFile = "/run/agenix/homebox_oidc_secret";
  };

  services.caddy = {
    enable = true;
    email = "infra@mbauce.com";
    virtualHosts."${domain}".extraConfig = ''
      encode zstd gzip
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        resolvers 1.1.1.1 8.8.8.8
      }
      reverse_proxy 127.0.0.1:7745
    '';
  };

  age.secrets.homebox_oidc_secret = {
    file = ../../secrets/homebox-oidc-client-secret.age;
    path = "/run/agenix/homebox-oidc.env";
    mode = "640";
    owner = "homebox";
    group = "homebox";
  };

  age.secrets.cloudflare = {
    file = ../../secrets/cloudflare_api_token.age;
    mode = "640";
    owner = "caddy";
    group = "caddy";
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.age.secrets.cloudflare.path
  ];

  services.caddy.package = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
    hash = "sha256-4qUWhrv3/8BtNCi48kk4ZvbMckh/cGRL7k+MFvXKbTw=";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
