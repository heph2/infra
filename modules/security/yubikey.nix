{ ... }: {
  flake.modules.nixos.yubikey = {
    services.pcscd.enable = true;
    hardware.gpgSmartcards.enable = true;
    services.yubikey-agent.enable = true;
    programs.yubikey-touch-detector.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
