{
  pkgs,
}:
let
  wrapped = pkgs.plakar.withPlugins (plugins: [
    plugins.remarkable
    plugins.routeros
    plugins.sftp
  ]);
in
assert pkgs.plakar.pname == "plakar";
assert pkgs.plakarPlugins.remarkable.pname == "plakar-remarkable";
assert pkgs.plakarPlugins.routeros.pname == "plakar-routeros";
assert pkgs.plakarPlugins.sftp.pname == "plakar-sftp";
assert wrapped.pname == "plakar-with-plugins";
{
  inherit wrapped;
  remarkable = pkgs.plakarPlugins.remarkable;
  routeros = pkgs.plakarPlugins.routeros;
}
