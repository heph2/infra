{
  config,
  pkgs,
  lib,
  ...
}:
let
  domain = "vikunja.pochi.casa";
  issuer = "https://auth.pochi.casa";
in
{
  services.vikunja = {
    enable = true;
    frontendHostname = domain;
    frontendScheme = "https";
    settings = {
      service = {
        publicurl = "https://${domain}";
        enableregistration = false;
      };
      auth = {
        local = {
          enabled = false;
        };
        openid = {
          enabled = true;
          redirecturl = "https://${domain}/auth/openid/";
          providers = [
            {
              name = "Authentik";
              authurl = issuer;
              logouturl = "${issuer}/application/o/vikunja/end-session/";
              clientid = "436a474a-15aa-444a-8ba1-e7dce352eb9d";
              # clientsecret is set via environment file
            }
          ];
        };
      };
    };
  };

  systemd.services.vikunja-api = {
    serviceConfig.EnvironmentFile = config.age.secrets.vikunja_oidc_secret.path;
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
      reverse_proxy 127.0.0.1:3456
    '';
  };

  age.secrets.vikunja_oidc_secret = {
    file = ../../secrets/vikunja-oidc-client-secret.age;
    path = "/run/agenix/vikunja-oidc.env";
    mode = "640";
    owner = "vikunja";
    group = "vikunja";
  };
}
