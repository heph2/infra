{ config, pkgs, ... }:

{
  age.secrets.paperless_oidc_secret = {
    file = "../../paperless-oidc-client-secret.age";
    mode = "640";
    owner = "paperless";
    group = "paperless";
  };

  services.paperless = {
    enable = true;
    settings = {
      PAPERLESS_URL = "https://paperless.pochi.casa";

      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";

      PAPERLESS_SOCIALACCOUNT_PROVIDERS = {
        openid_connect = {
          APPS = [
            {
              provider_id = "pocketid";
              name = "Pocket ID";
              client_id = "a76dd172-aabe-4366-942d-b56fd7704ae5";
              secret = config.age.secrets.paperless_oidc_secret.path;
              settings = {
                server_url = "https://auth.pochi.casa/.well-known/openid-configuration";
              };
            }
          ];
        };
      };

      PAPERLESS_DISABLE_REGULAR_LOGIN = true;
      PAPERLESS_REDIRECT_LOGIN_TO_SSO = true;
    };
  };
}
