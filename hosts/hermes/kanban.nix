{ config, lib, pkgs, ... }: {
  services.vikunja = {
    enable = true;
    frontendHostname = "hermes.hippo-bonito.ts.net";
    frontendScheme = "http";
  };
  services.nginx.virtualHosts."hermes.hippo-bonito.ts.net" = {
    listen = [{ addr = "100.101.63.124"; }];
  };
}
