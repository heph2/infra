{
  inputs,
  pkgs,
  ...
}:
{
  # Use the newer Microsoft packages already pinned by the independently
  # updated nixpkgs input while testing the OneAuth web-navigation error 2604.
  nixpkgs.overlays = [
    (
      final: _prev:
      let
        intunePkgs = import inputs.plakar-nixpkgs {
          system = final.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      in
      {
        inherit (intunePkgs) intune-portal microsoft-identity-broker;
      }
    )
  ];

  # Experimental: Intune officially supports Ubuntu/RHEL with GNOME, not
  # NixOS/COSMIC. Nixpkgs packages Microsoft's Ubuntu binaries and wires their
  # systemd and D-Bus services; GNOME Keyring provides the secret store they
  # expect even though COSMIC remains the desktop session.
  services.intune.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Intune's Conditional Access flow for Linux requires Microsoft Edge.
  environment.systemPackages = [ pkgs.microsoft-edge ];
}
