{ pkgs, ... }:
{
  # Experimental: Intune officially supports Ubuntu/RHEL with GNOME, not
  # NixOS/COSMIC. Nixpkgs packages Microsoft's Ubuntu binaries and wires their
  # systemd and D-Bus services; GNOME Keyring provides the secret store they
  # expect even though COSMIC remains the desktop session.
  services.intune.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Intune's Conditional Access flow for Linux requires Microsoft Edge.
  environment.systemPackages = [ pkgs.microsoft-edge ];
}
