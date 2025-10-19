{ stdenv, dpkg }:

stdenv.mkDerivation (_finalAttrs: {
  pname = "mesa-starfive";
  version = "0.13.0";
  src = fetchTarball {
    url = "https://github.com/starfive-tech/Debian/releases/download/v0.13.0-engineering-release-wayland/mesa-debs.tar.gz";
    sha256 = "sha256:18xwjbd9jz78mp218y8qj8mji2m1kp92jfwz4q85rwwnw79hddb0";
  };

  nativeBuildInputs = [ dpkg ];

  installPhase = ''
    mkdir -p $out
    for deb in *.deb; do
      dpkg-deb -x "$deb" $out
    done
  '';
})
