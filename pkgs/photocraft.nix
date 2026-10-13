{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, vulkan-loader
, libGL
, wayland
, libxkbcommon
, libx11
, libxcursor
, libxi
, libxrandr
, libxcb
, fontconfig
, gtk3
}:

let
  libs = [
    vulkan-loader
    libGL
    wayland
    libxkbcommon
    libx11
    libxcursor
    libxi
    libxrandr
    libxcb
    fontconfig
    gtk3
  ];
in
stdenv.mkDerivation rec {
  pname = "photocraft";
  version = "0.8.2";

  src = fetchurl {
    url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-linux-x86_64.tar.gz";
    hash = "sha256-FsMImXbu4tKQ2+c5httINcHsWgQ8XBawF7JISP9eqCc=";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r bin share $out/
    # wgpu/winit dlopen these at runtime
    for b in photocraft photocraft-cli; do
      wrapProgram $out/bin/$b --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath libs}
    done
    runHook postInstall
  '';

  meta = {
    description = "Open-source Photoshop-style photo editor written in Rust";
    homepage = "https://github.com/storytold/photocraft";
    license = with lib.licenses; [ mit asl20 ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "photocraft";
  };
}
