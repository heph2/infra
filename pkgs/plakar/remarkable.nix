{
  lib,
  buildGo126Module,
  fetchFromGitHub,
  plakar,
}:

buildGo126Module rec {
  pname = "plakar-remarkable";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "heph2";
    repo = "plakar-integration-remarkable";
    rev = "v${version}";
    hash = "sha256-durYo9BFj8UpFyY0KFbn1vMQLFHD9QSWJB8Y6cqlesk=";
  };

  vendorHash = "sha256-3CF+HbgSsTEU/b9unTybK2usDdMVDZIdvKE90RtyhuA=";
  subPackages = [ "cmd/importer" ];

  postInstall = ''
    pluginRoot="$TMPDIR/remarkable-plugin"
    install -Dm644 manifest.yaml "$pluginRoot/manifest.yaml"
    install -Dm644 importer/schema.json "$pluginRoot/importer/schema.json"
    install -Dm755 "$out/bin/importer" "$pluginRoot/remarkable-importer"

    mkdir -p "$out/share/plakar/plugins" "$TMPDIR/data" "$TMPDIR/cache"
    HOME="$TMPDIR" ${lib.getExe plakar} \
      -datadir "$TMPDIR/data" \
      -cachedir "$TMPDIR/cache" \
      pkg create \
      -out "$out/share/plakar/plugins/remarkable_v${version}_''${GOOS}_''${GOARCH}.ptar" \
      "$pluginRoot/manifest.yaml" v${version}

    rm -rf "$out/bin"
  '';

  meta = {
    description = "Plakar integration for reMarkable tablet backups";
    homepage = "https://github.com/heph2/plakar-integration-remarkable";
    license = lib.licenses.isc;
    platforms = lib.platforms.unix;
  };
}
