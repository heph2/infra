{ config, pkgs, ... }:

{
  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://auth.pochi.casa";
      TRUST_PROXY = true;
      ANALYTICS_DISABLED = true;
      HOST = "::";
      PORT = 1411;
    };
    environmentFile = "/tmp/pocket.env";
  };
}
