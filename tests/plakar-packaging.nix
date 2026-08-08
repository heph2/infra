{
  pkgs,
}:
let
  wrapped = pkgs.plakar.withPlugins (plugins: [ plugins.routeros ]);
in
assert pkgs.plakar.pname == "plakar";
assert pkgs.plakarPlugins.routeros.pname == "plakar-routeros";
assert wrapped.pname == "plakar-with-plugins";
{
  inherit wrapped;
  routeros = pkgs.plakarPlugins.routeros;
}
