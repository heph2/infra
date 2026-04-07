{
  config,
  pkgs,
  lib,
  ...
}:
let
  domain = "pass.pochi.casa";
  issuer = "https://auth.pochi.casa";
in
{
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "/var/backup/vaultwarden";
    config = {
      DOMAIN = "https://${domain}";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = true;
      INVITATIONS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;
      SSO_ENABLED = true;
      SSO_SIGNUPS_MATCH_EMAIL = true;
      SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION = true;
      SSO_PKCE = false;
      SSO_SCOPES = "email profile groups offline_access";
      SSO_CLIENT_ID = "418ad0f4-ab95-4945-96fc-d22c1e1d3a4e";
      SSO_AUTHORITY = issuer;
    };
    environmentFile = config.age.secrets.vaultwarden-oidc-client-secret.path;
  };

  age.secrets.vaultwarden-oidc-client-secret = {
    file = ../../secrets/vaultwarden-oidc-client-secret.age;
    mode = "440";
    owner = "vaultwarden";
    group = "vaultwarden";
  };

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    encode zstd gzip
    tls {
      dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      resolvers 1.1.1.1 8.8.8.8
    }
    reverse_proxy 127.0.0.1:8222
  '';

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
