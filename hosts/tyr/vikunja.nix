{ config, pkgs, lib, ... }:
let
  domain = "vikunja.pochi.casa";
  issuer = "https://auth.pochi.casa";
in {
  services.vikunja = {
    enable = true;
    frontendHostname = domain;
    frontendScheme = "https";
    # Override settings completely with mkForce to include all required defaults
    # plus our OpenID configuration (without the secret)
    settings = lib.mkForce {
      service = {
        publicurl = "https://${domain}";
        enableregistration = false;
        interface = ":3456";
        frontendurl = "https://${domain}/";
      };
      database = {
        type = "sqlite";
        path = "/var/lib/vikunja/vikunja.db";
      };
      files = { basepath = "/var/lib/vikunja/files"; };
      auth = {
        local = { enabled = false; };
        openid = {
          enabled = true;
          redirecturl = "https://${domain}/auth/openid/";
          # Client secret will be substituted by activation script
          providers = [{
            name = "Pocket-ID";
            authurl = issuer;
            logouturl = "${issuer}/application/o/vikunja/end-session/";
            clientid = "436a474a-15aa-444a-8ba1-e7dce352eb9d";
            clientsecret = "PLACEHOLDER_WILL_BE_REPLACED";
            scope = "openid profile email";
          }];
        };
      };
    };
  };

  # Use activation script to substitute the secret in /etc/vikunja/config.yaml
  # This runs during system activation with root permissions
  system.activationScripts.vikunja-secret = lib.mkAfter ''
    # Read the secret from the local file
    if [ -f /var/lib/vikunja/oidc-secret.env ]; then
      SECRET=$(grep -oP '(?<=^VIKUNJA_AUTH_OPENID_PROVIDERS_0_CLIENTSECRET=).*' /var/lib/vikunja/oidc-secret.env)
      if [ -n "$SECRET" ]; then
        ${pkgs.gnused}/bin/sed -i "s/PLACEHOLDER_WILL_BE_REPLACED/$SECRET/g" /etc/vikunja/config.yaml
        echo "Vikunja: Client secret substituted successfully"
      else
        echo "Vikunja: Warning - could not read secret from /var/lib/vikunja/oidc-secret.env"
      fi
    else
      echo "Vikunja: Warning - secret file not found at /var/lib/vikunja/oidc-secret.env"
    fi
  '';

  # Ensure the secret file exists with correct permissions
  systemd.tmpfiles.rules = [ "d /var/lib/vikunja 0750 vikunja vikunja - -" ];

  age.secrets.vikunja_oidc_secret = {
    file = ../../secrets/vikunja-oidc-client-secret.age;
    path = "/run/agenix/vikunja-oidc.env";
    mode = "640";
    owner = "vikunja";
    group = "vikunja";
  };
}
