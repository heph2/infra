{ fetchFromGitHub
, buildGoModule
, lib
}:

buildGoModule rec {
  pname = "mblaze-ui";
  version = "master";

  src = fetchFromGitHub {
    owner = "nmeum";
    repo = "mblaze-ui";
    rev = "master";
    sha256 = "sha256-wX1bQwr+ANZGpywEHKtGtCKjmTeeQPSME5cJ1Y6UjoA=";
  };

  vendorHash = "sha256-V6QgsyG95jxoPQy2X6WqfJsrzYH/kaOuWG3nykXAlo8=";

  doCheck = false;

  meta = {
    description = "A TUI frontend for mblaze";
    homepage = "https://github.com/nmeum/mblaze-ui";
    license = lib.licenses.isc;
    maintainers = [ ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}

