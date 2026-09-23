{
  lib,
  buildGo126Module,
  fetchFromGitHub,
  plakar,
}:

buildGo126Module rec {
  pname = "plakar-rclone";
  version = "1.1.0-beta.1";

  src = fetchFromGitHub {
    owner = "PlakarKorp";
    repo = "integrations";
    # PR 168: keep rclone's OAuth token refresh context alive after Init.
    rev = "81f18a7b1e62cd6587a019d7c67b67b58341a356";
    hash = "sha256-9HNdtvmpuSoiCersl31xsbC7Ud/aEuao79aI7DVWnog=";
  };

  sourceRoot = "source/rclone";
  vendorHash = "sha256-w1BKzziY0imRLs8PYhId4jvwKZLd9dWJrohDYsGEvvg=";
  subPackages = [
    "plugin/importer"
    "plugin/exporter"
    "plugin/storage"
  ];

  postInstall = ''
    pluginRoot="$TMPDIR/rclone-plugin"
    install -Dm644 manifest.yaml "$pluginRoot/manifest.yaml"
    install -Dm755 "$out/bin/importer" "$pluginRoot/rclone-importer"
    install -Dm755 "$out/bin/exporter" "$pluginRoot/rclone-exporter"
    install -Dm755 "$out/bin/storage" "$pluginRoot/rclone-storage"

    mkdir -p "$out/share/plakar/plugins" "$TMPDIR/data" "$TMPDIR/cache"
    HOME="$TMPDIR" ${lib.getExe plakar} \
      -datadir "$TMPDIR/data" \
      -cachedir "$TMPDIR/cache" \
      pkg create \
      -out "$out/share/plakar/plugins/rclone_v${version}_''${GOOS}_''${GOARCH}.ptar" \
      "$pluginRoot/manifest.yaml" v${version}

    rm -rf "$out/bin"
  '';

  meta = {
    description = "Plakar integration for Rclone cloud storage backends";
    homepage = "https://github.com/PlakarKorp/integration-rclone";
    license = lib.licenses.isc;
    platforms = lib.platforms.unix;
  };
}
