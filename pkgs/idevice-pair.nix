{ lib
, rustPlatform
, fetchFromGitHub
, fetchurl
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, vulkan-loader
, libGL
, wayland
, libxkbcommon
, libx11
, libxcursor
, libxi
, libxrandr
}:

let
  # build.rs downloads these at build time (not possible in the sandbox) and skips
  # any file already present in DDI/, so pin and pre-fetch them.
  ddiRev = "a719045a6470a8db988235230f6430b2b7df51fe";
  ddi = name: hash: fetchurl {
    url = "https://github.com/doronz88/DeveloperDiskImage/raw/${ddiRev}/PersonalizedImages/Xcode_iOS_DDI_Personalized/${name}";
    inherit hash;
  };
  ddiFiles = {
    "BuildManifest.plist" = ddi "BuildManifest.plist" "sha256-jt1KL09O8fvXv+SXhdi63Gc9E5XR2U2FsTLKirXsr1Q=";
    "Image.dmg" = ddi "Image.dmg" "sha256-Bf2AfaXhnwMPpJQfJIAMllxsd5gqtXLdXR73ePtp+co=";
    "Image.dmg.trustcache" = ddi "Image.dmg.trustcache" "sha256-Nq9giJ/1pzeHSiba644aATnr/r7G7C5Nj2o8G/Hc41w=";
  };
in
rustPlatform.buildRustPackage rec {
  pname = "idevice-pair";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "jkcoxson";
    repo = "idevice_pair";
    rev = "v${version}";
    hash = "sha256-Bxq1yrL6MVD5nXdIl90C13bQL6l5HffdwXcU3Zf9QA0=";
  };

  cargoHash = "sha256-5Kuu+keWfact5VJKzQJNNHKBkxjJWL55cIxmSvlXV6U=";

  postPatch = ''
    mkdir -p DDI
    ${lib.concatStrings (lib.mapAttrsToList (n: f: "cp ${f} DDI/${n}\n") ddiFiles)}
  '';

  nativeBuildInputs = [ makeWrapper copyDesktopItems ];

  # eframe/winit dlopen these at runtime
  postFixup = ''
    wrapProgram $out/bin/idevice_pair --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
      vulkan-loader libGL wayland libxkbcommon libx11 libxcursor libxi libxrandr
    ]}
    install -Dm444 icon.png $out/share/icons/hicolor/512x512/apps/idevice_pair.png
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "idevice_pair";
      desktopName = "idevice pair";
      comment = "Generate pair records for iOS and save them";
      exec = "idevice_pair";
      icon = "idevice_pair";
      categories = [ "Utility" ];
    })
  ];

  meta = {
    description = "Generate pair records for iOS and save them";
    homepage = "https://github.com/jkcoxson/idevice_pair";
    platforms = [ "x86_64-linux" ];
    mainProgram = "idevice_pair";
  };
}
