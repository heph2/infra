{
  appimageTools,
  fetchurl,
  lib,
}:

appimageTools.wrapType2 rec {
  pname = "orca-ide";
  version = "1.4.209";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-xsYrHU3TFQocrfzG3KdjMWyOkjNt2pirzL61U6B+PuM=";
  };

  extraInstallCommands =
    let
      contents = appimageTools.extractType2 { inherit pname version src; };
    in
    ''
      install -Dm444 ${contents}/orca-ide.desktop $out/share/applications/orca-ide.desktop
      substituteInPlace $out/share/applications/orca-ide.desktop \
        --replace-fail 'Exec=AppRun %U' 'Exec=orca-ide %U'

      for size in 16 24 32 48 64 128 256 512; do
        install -Dm444 \
          ${contents}/usr/share/icons/hicolor/$size"x"$size/apps/orca-ide.png \
          $out/share/icons/hicolor/$size"x"$size/apps/orca-ide.png
      done
    '';

  meta = {
    description = "Agent development environment for parallel coding agents";
    homepage = "https://www.onorca.dev/";
    license = lib.licenses.mit;
    mainProgram = "orca-ide";
    platforms = [ "x86_64-linux" ];
  };
}
