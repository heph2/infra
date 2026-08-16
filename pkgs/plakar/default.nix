{ inputs }:
_final: _prev:
let
  plakarPkgs = import inputs.plakar-nixpkgs {
    system = _prev.stdenv.hostPlatform.system;
  };

  plugins = {
    remarkable = plakarPkgs.callPackage ./remarkable.nix { };
    routeros = plakarPkgs.callPackage ./routeros.nix { };
  };

  basePlakar = plakarPkgs.plakar;
in
{
  plakarPlugins = plugins;

  plakar = basePlakar.overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      withPlugins =
        select:
        plakarPkgs.callPackage ./with-plugins.nix {
          plakar = basePlakar;
          plugins = select plugins;
        };
    };
  });
}
