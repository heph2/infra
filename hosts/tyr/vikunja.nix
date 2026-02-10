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
          # Client secret will be added via environment variable
          providers = [{
            name = "Pocket-ID";
            authurl = issuer;
            logouturl = "${issuer}/application/o/vikunja/end-session/";
            clientid = "436a474a-15aa-444a-8ba1-e7dce352eb9d";
            clientsecret = "placeholder-will-be-replaced";
            scope = "openid profile email";
          }];
        };
      };
    };
    # Add environment file for the secret
    environmentFiles = [ config.age.secrets.vikunja_oidc_secret.path ];
  };

  # Override the generated config file to substitute the secret
  # We use a systemd tmpfiles rule to create a modified version
  systemd.tmpfiles.rules = [ "d /var/lib/vikunja 0750 vikunja vikunja - -" ];

  # Override the systemd service to substitute the secret before starting
  systemd.services.vikunja = {
    # Override the ExecStart to use a wrapper script
    serviceConfig = {
      ExecStart = lib.mkForce (pkgs.writeShellScript "vikunja-wrapper" ''
        set -e

        # The secret is loaded via EnvironmentFile into VIKUNJA_AUTH_OPENID_PROVIDERS_0_CLIENTSECRET
        if [ -z "$VIKUNJA_AUTH_OPENID_PROVIDERS_0_CLIENTSECRET" ]; then
          echo "ERROR: VIKUNJA_AUTH_OPENID_PROVIDERS_0_CLIENTSECRET environment variable not set" >&2
          exit 1
        fi

        # Copy the config file and substitute the secret
        sed "s/placeholder-will-be-replaced/$VIKUNJA_AUTH_OPENID_PROVIDERS_0_CLIENTSECRET/g" /etc/vikunja/config.yaml > /var/lib/vikunja/config.yaml
        chmod 640 /var/lib/vikunja/config.yaml

        # Start vikunja with the modified config
        exec ${pkgs.vikunja}/bin/vikunja
      '');
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
