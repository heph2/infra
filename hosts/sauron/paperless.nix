{
  config,
  pkgs,
  lib,
  ...
}:
{
  age.secrets.paperless_oidc_secret = {
    file = ../../secrets/paperless-oidc-client-secret.age;
    mode = "640";
    owner = "paperless";
    group = "paperless";
  };

  services.paperless = {
    enable = true;
    environmentFile = config.age.secrets.paperless_oidc_secret.path;
    settings = {
      PAPERLESS_URL = "https://paperless.pochi.casa";
      PAPERLESS_SOCIAL_AUTO_SIGNUP = true;
    };
  };
}
