{ config, pkgs, lib, ... }:
let
  domain = "grafana.pochi.casa";
  issuer = "https://auth.pochi.casa";
in {
  services.grafana = {
    enable = true;
    domain = domain;
    port = 3000;
    addr = "127.0.0.1";
    settings = {
      server = { root_url = "https://${domain}"; };
      auth = {
        disable_login_form = true;
        disable_signout_menu = true;
      };
    };
  };

  # systemd.services.grafana = {
  #   serviceConfig.EnvironmentFile = "/run/agenix/grafana-oidc";
  #   serviceConfig.Environment = [
  #     "GF_AUTH_GENERIC_OAUTH_ENABLED=true"
  #     "GF_AUTH_GENERIC_OAUTH_NAME=Pocket-ID"
  #     "GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP=true"
  #     "GF_AUTH_GENERIC_OAUTH_CLIENT_ID=1fd4e11a-61de-4c23-a820-6a4645829ac7"
  #     "GF_AUTH_GENERIC_OAUTH_SCOPES=openid profile email"
  #     "GF_AUTH_GENERIC_OAUTH_AUTH_URL=${issuer}/authorize"
  #     "GF_AUTH_GENERIC_OAUTH_TOKEN_URL=${issuer}/oauth/token"
  #     "GF_AUTH_GENERIC_OAUTH_API_URL=${issuer}/userinfo"
  #   ];
  # };

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
