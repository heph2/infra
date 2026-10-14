# nixpkgs iloader bumped to 2.3.7. The upstream AppImage showed a blank window
# (bundled WebKit can't create an EGL display), so build from source instead.
{ lib, iloader, fetchFromGitHub, rustPlatform }:

iloader.overrideAttrs (final: prev: {
  version = "2.3.7";

  src = fetchFromGitHub {
    owner = "nab138";
    repo = "iloader";
    rev = "v${final.version}";
    hash = "sha256-ym7/KMkcYskJKLciBqsdBic9a8akiLtPh97Osmw7K+g=";
  };

  nodeModules = prev.nodeModules.overrideAttrs {
    outputHash = "sha256-v6Hy3fmbpArVJh0YLJZGKH65nXiWPMjUsu1nPKdHlQ8=";
  };

  # buildRustPackage reads the original cargoHash, so vendor the crates explicitly
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (final) pname version src cargoRoot;
    hash = "sha256-O8fjKaWj6qeO7tliAs2n2e8NtEWlmt/qFffYOBe52Yo=";
  };
})
