{ config, pkgs, ... }:

{
  age.secrets.pocket-id-encryption-key = {
    file = ../../secrets/pocket-id-encryption-key.age;
    mode = "400";
    owner = "pocket-id";
    group = "pocket-id";
  };

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://auth.pochi.casa";
      TRUST_PROXY = true;
      ANALYTICS_DISABLED = true;
      HOST = "::";
      PORT = 1411;
    };
    environmentFile = config.age.secrets.pocket-id-encryption-key.path;
  };
}
