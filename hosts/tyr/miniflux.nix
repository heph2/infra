{ config, pkgs, ... }:
let
  domain = "feed.pochi.casa";
  issuer = "https://auth.pochi.casa";
in {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [ "miniflux" ];
    ensureUsers = [{
      name = "miniflux";
      ensureDBOwnership = true;
    }];
  };

  services.miniflux = {
    enable = true;
    settings = {
      BASE_URL = "https://${domain}";
      LISTEN_ADDR = "127.0.0.1:8080";
    };
    environmentFiles = [
      config.age.secrets.miniflux-db.path
      config.age.secrets.miniflux-oidc.path
    ];
  };

  systemd.services.miniflux.environment = {
    OAUTH2_PROVIDER = "oidc";
    OAUTH2_CLIENT_ID = "miniflux";
    OAUTH2_REDIRECT_URL = "https://${domain}/oauth2/oidc/callback";
    OAUTH2_OIDC_DISCOVERY_ENDPOINT = issuer;
    OAUTH2_USER_CREATION = "1";
  };

  age.secrets.miniflux-db = {
    file = ../../secrets/miniflux-db.password.age;
    mode = "640";
    owner = "miniflux";
    group = "miniflux";
  };

  age.secrets.miniflux-oidc = {
    file = ../../secrets/miniflux-oidc-client-secret.age;
    mode = "640";
    owner = "miniflux";
    group = "miniflux";
  };

  age.secrets.cloudflare = {
    file = ../../secrets/cloudflare_api_token.age;
    mode = "640";
    owner = "caddy";
    group = "caddy";
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
      reverse_proxy 127.0.0.1:8080
    '';
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile =
    [ config.age.secrets.cloudflare.path ];

  services.caddy.package = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
    hash = "sha256-dnhEjopeA0UiI+XVYHYpsjcEI6Y1Hacbi28hVKYQURg=";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
