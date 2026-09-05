{
  lib,
  buildGo126Module,
  fetchFromGitHub,
  plakar,
}:

buildGo126Module rec {
  pname = "plakar-sftp";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "PlakarKorp";
    repo = "integration-sftp";
    rev = "v${version}";
    hash = "sha256-LwbO/0jSeUYlyHCK9RJ4DUH5VlHWRSmp6CPndQfp+rQ=";
  };

  vendorHash = "sha256-+L/U2SidX5JujgKQ8AYJnXrsUl0zZkwBr36uV5WK9bY=";
  subPackages = [
    "plugin/importer"
    "plugin/exporter"
    "plugin/storage"
  ];

  postInstall = ''
    pluginRoot="$TMPDIR/sftp-plugin"
    install -Dm644 manifest.yaml "$pluginRoot/manifest.yaml"
    install -Dm644 importer/schema.json "$pluginRoot/importer/schema.json"
    install -Dm644 exporter/schema.json "$pluginRoot/exporter/schema.json"
    install -Dm644 storage/schema.json "$pluginRoot/storage/schema.json"
    install -Dm755 "$out/bin/importer" "$pluginRoot/sftpImporter"
    install -Dm755 "$out/bin/exporter" "$pluginRoot/sftpExporter"
    install -Dm755 "$out/bin/storage" "$pluginRoot/sftpStorage"

    mkdir -p "$out/share/plakar/plugins" "$TMPDIR/data" "$TMPDIR/cache"
    HOME="$TMPDIR" ${lib.getExe plakar} \
      -datadir "$TMPDIR/data" \
      -cachedir "$TMPDIR/cache" \
      pkg create \
      -out "$out/share/plakar/plugins/sftp_v${version}_''${GOOS}_''${GOARCH}.ptar" \
      "$pluginRoot/manifest.yaml" v${version}

    rm -rf "$out/bin"
  '';

  meta = {
    description = "Plakar integration for SFTP storage and transfers";
    homepage = "https://github.com/PlakarKorp/integration-sftp";
    license = lib.licenses.isc;
    platforms = lib.platforms.unix;
  };
}
