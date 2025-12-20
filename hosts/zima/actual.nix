{
  config,
  pkgs,
  inputs,
  ...
}:

{
  inputs.age.secrets.actual-oidc-client-secret = {
    file = ../secrets/actual-oidc-client-secret.age;
    owner = "actual";
    group = "actual";
    mode = "0400";
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
