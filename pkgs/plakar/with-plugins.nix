{
  lib,
  makeWrapper,
  plakar,
  plugins,
  symlinkJoin,
}:

symlinkJoin {
  pname = "plakar-with-plugins";
  inherit (plakar) version;
  name = "plakar-with-plugins-${plakar.version}";
  paths = [ plakar ];
  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    mkdir -p "$out/share/plakar" "$TMPDIR/cache"
    shopt -s nullglob
    for plugin in ${lib.escapeShellArgs plugins}; do
      for archive in "$plugin"/share/plakar/plugins/*.ptar; do
        HOME="$TMPDIR" ${lib.getExe plakar} \
          -datadir "$out/share/plakar" \
          -cachedir "$TMPDIR/cache" \
          pkg add "$archive"
      done
    done

    # Plakar ignores these temporary files, but their random names would make
    # the Nix output non-reproducible.
    find "$out/share/plakar/plugins" -type f -name '.*' -delete

    rm "$out/bin/plakar"
    makeWrapper ${lib.getExe plakar} "$out/bin/plakar" \
      --add-flags "-datadir $out/share/plakar"
  '';

  passthru = {
    inherit plugins;
    unwrapped = plakar;
  };

  meta = plakar.meta // {
    description = "Plakar with a declarative set of plugins";
  };
}
