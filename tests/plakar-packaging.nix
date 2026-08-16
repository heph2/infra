{
  pkgs,
}:
let
  wrapped = pkgs.plakar.withPlugins (plugins: [
    plugins.remarkable
    plugins.routeros
  ]);
in
assert pkgs.plakar.pname == "plakar";
assert pkgs.plakarPlugins.remarkable.pname == "plakar-remarkable";
assert pkgs.plakarPlugins.routeros.pname == "plakar-routeros";
assert wrapped.pname == "plakar-with-plugins";
{
  inherit wrapped;
  remarkable = pkgs.plakarPlugins.remarkable;
  routeros = pkgs.plakarPlugins.routeros;
}
