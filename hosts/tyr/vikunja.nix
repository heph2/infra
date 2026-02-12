{
  config,
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
    environmentFiles = [ config.age.secrets.vikunja_oidc_secret.path ];
    settings = { };
  };

  # OIDC config via environment (secret comes from environmentFiles)
  systemd.services.vikunja.environment = {
    VIKUNJA_AUTH_LOCAL_ENABLED = "false";
    VIKUNJA_AUTH_OPENID_ENABLED = "true";
    VIKUNJA_AUTH_OPENID_REDIRECTURL = "https://${domain}/auth/openid/pocketid";
    VIKUNJA_AUTH_OPENID_PROVIDERS_POCKETID_NAME = "Pocket-ID";
    VIKUNJA_AUTH_OPENID_PROVIDERS_POCKETID_AUTHURL = issuer;
    VIKUNJA_AUTH_OPENID_PROVIDERS_POCKETID_LOGOUTURL = "${issuer}/api/oidc/end-session/";
    VIKUNJA_AUTH_OPENID_PROVIDERS_POCKETID_CLIENTID = "436a474a-15aa-444a-8ba1-e7dce352eb9d";
    VIKUNJA_AUTH_OPENID_PROVIDERS_POCKETID_SCOPE = "openid profile email";
  };

  age.secrets.vikunja_oidc_secret = {
    file = ../../secrets/vikunja-oidc-client-secret.age;
    path = "/run/agenix/vikunja-oidc.env";
  };

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    encode zstd gzip
    tls {
      dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      resolvers 1.1.1.1 8.8.8.8
    }
    reverse_proxy 127.0.0.1:3456
  '';
}
