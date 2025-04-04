{ lib
, stdenv
, fetchurl
, fetchgit
, pkg-config
, flac
, libmpg123
, libvorbis
, opusfile
, libao
, libmd
, glib
}:

stdenv.mkDerivation rec {
  pname = "amused";
  version = "0.18";

  src = fetchurl {
    url = "https://ftp.omarpolo.com/${pname}-${version}.tar.gz";
    sha256 = "sha256-HqSfmzeTDVv3WvzIX/meeyKBhwwWI0+H4knOcz39pbo=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    flac
    libmpg123
    libvorbis
    opusfile
    libao
    libmd
    glib
  ];

  configureFlags = [ "--backend=ao" "--with-mpris2" ];

  meta = with lib; {
    description = "amused is a simple music player";
    homepage = "https://amused.omarpolo.com";
    license = licenses.isc;
    platforms = platforms.unix;
  };
}
