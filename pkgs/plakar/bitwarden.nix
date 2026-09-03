{
  lib,
  buildGo126Module,
  fetchFromGitHub,
  plakar,
}:

buildGo126Module rec {
  pname = "plakar-bitwarden";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "heph2";
    repo = "plakar-integration-bitwarden";
    rev = "v${version}";
    hash = "sha256-eVwJRsCVeIXNe0/FS1Y/BbShEElBLZ0FBgvHVH28HGc=";
  };

  vendorHash = "sha256-p0lC7zOcPP+YvTwLogChKHqAdCyj4bU3aVTzeUGYLOg=";
  subPackages = [ "cmd/importer" ];

  postInstall = ''
    pluginRoot="$TMPDIR/bitwarden-plugin"
    install -Dm644 manifest.yaml "$pluginRoot/manifest.yaml"
    install -Dm644 importer/schema.json "$pluginRoot/importer/schema.json"
    install -Dm755 "$out/bin/importer" "$pluginRoot/bitwarden-importer"

    mkdir -p "$out/share/plakar/plugins" "$TMPDIR/data" "$TMPDIR/cache"
    HOME="$TMPDIR" ${lib.getExe plakar} \
      -datadir "$TMPDIR/data" \
      -cachedir "$TMPDIR/cache" \
      pkg create \
      -out "$out/share/plakar/plugins/bitwarden_v${version}_''${GOOS}_''${GOARCH}.ptar" \
      "$pluginRoot/manifest.yaml" v${version}

    rm -rf "$out/bin"
  '';

  meta = {
    description = "Plakar integration for logical Bitwarden vault backups";
    homepage = "https://github.com/heph2/plakar-integration-bitwarden";
    license = lib.licenses.isc;
    platforms = lib.platforms.unix;
  };
}
