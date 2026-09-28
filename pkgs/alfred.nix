{
  writeShellApplication,
  babashka,
  hledger,
  vja,
  just,
  nix,
}:

writeShellApplication {
  name = "alfred";
  runtimeInputs = [
    babashka
    hledger
    vja
    just
    nix
  ];
  text = ''
    if [[ -z "''${ALFRED_DATA_FILE:-}" ]]; then
      if [[ -f data/network.edn ]]; then
        export ALFRED_DATA_FILE="$PWD/data/network.edn"
      else
        export ALFRED_DATA_FILE="${../data/network.edn}"
      fi
    fi
    exec bb -cp ${../cli} -m alfred "$@"
  '';
}
