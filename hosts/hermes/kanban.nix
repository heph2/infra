{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.vikunja = {
    enable = false;
    frontendHostname = "hermes.hippo-bonito.ts.net";
    frontendScheme = "http";
  };
}
