{
  lib,
  buildGo126Module,
  fetchFromGitHub,
  plakar,
}:

buildGo126Module rec {
  pname = "plakar-routeros";
  version = "1.1.0-unstable-2026-08-07";

  src = fetchFromGitHub {
    owner = "PlakarKorp";
    repo = "integrations";
    rev = "96a786275c2d498d131f071394c919440a992290";
    hash = "sha256-4bxBnPwHmmLrGjybxZepQ54uzQT/Y/xWjndVqz7LSqM=";
  };

  sourceRoot = "${src.name}/routeros";
  vendorHash = "sha256-3CF+HbgSsTEU/b9unTybK2usDdMVDZIdvKE90RtyhuA=";

  subPackages = [
    "cmd/importer"
    "cmd/exporter"
  ];

  postInstall = ''
    pluginRoot="$TMPDIR/routeros-plugin"
    install -Dm644 manifest.yaml "$pluginRoot/manifest.yaml"
    install -Dm755 "$out/bin/importer" "$pluginRoot/routeros-importer"
    install -Dm755 "$out/bin/exporter" "$pluginRoot/routeros-exporter"

    mkdir -p "$out/share/plakar/plugins" "$TMPDIR/data" "$TMPDIR/cache"
    HOME="$TMPDIR" ${lib.getExe plakar} \
      -datadir "$TMPDIR/data" \
      -cachedir "$TMPDIR/cache" \
      pkg create \
      -out "$out/share/plakar/plugins/routeros_v1.1.0_''${GOOS}_''${GOARCH}.ptar" \
      "$pluginRoot/manifest.yaml" v1.1.0

    rm -rf "$out/bin"
  '';

  meta = {
    description = "Plakar integration for RouterOS configuration backups";
    homepage = "https://github.com/PlakarKorp/integrations/tree/integration/routeros/routeros";
    license = lib.licenses.isc;
    platforms = lib.platforms.unix;
  };
}
