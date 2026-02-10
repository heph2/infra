{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  domain = "vikunja.pochi.casa";
  issuer = "https://auth.pochi.casa";
in
{
  services.vikunja = {
    enable = true;
    package = vikunja-unstable;
    frontendHostname = domain;
    frontendScheme = "https";
    environmentFiles = [ config.age.secrets.vikunja_oidc_secret.path ];
    settings = {
      service = {
        publicurl = "https://${domain}";
        enableregistration = false;
        frontendurl = "https://${domain}/";
      };
      auth = {
        local = {
          enabled = false;
        };
        openid = {
          enabled = true;
          redirecturl = "https://${domain}/auth/openid/pocketid";
          providers = [
            {
              name = "Pocket-ID";
              authurl = issuer;
              logouturl = "${issuer}/api/oidc/end-session/";
              clientid = "436a474a-15aa-444a-8ba1-e7dce352eb9d";
              scope = "openid profile email";
            }
          ];
        };
      };
    };
  };

  age.secrets.vikunja_oidc_secret = {
    file = ../../secrets/vikunja-oidc-client-secret.age;
    path = "/run/agenix/vikunja-oidc.env";
    mode = "640";
    owner = "vikunja";
    group = "vikunja";
  };
}
