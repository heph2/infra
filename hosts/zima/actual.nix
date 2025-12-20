{
  config,
  pkgs,
  lib,
  ...
}:

{
  users.groups.actual = { };
  users.users.actual = {
    isSystemUser = true;
    group = "actual";
    home = "/var/lib/actual";
    createHome = true;
  };

  # Override the unit: DynamicUser must be disabled
  systemd.services.actual.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "actual";
    Group = lib.mkForce "actual";
  };

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.actual-oidc-client-secret = {
    file = ../../secrets/actual-oidc-client-secret.age;
    owner = "actual";
    group = "actual";
    mode = "0440";
  };

  services.actual = {
    enable = true;
    settings = {
      hostname = "::";
      port = 5006;
      openId = {
        discoveryURL = "https://auth.pochi.casa/.well-known/openid-configuration";
        client_id = "0fa04795-9c36-4385-95c6-820731758fbd";
        client_secret._secret = config.age.secrets.actual-oidc-client-secret.path;
        server_hostname = "https://budget.pochi.casa";
        authMethod = "oauth2";
      };
    };
  };
}
