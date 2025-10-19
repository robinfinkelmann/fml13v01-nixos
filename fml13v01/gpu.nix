{ stdenv }:

stdenv.mkDerivation (_finalAttrs: {
  pname = "img-gpu-powervr-bin";
  version = "1.19.6345021";
  src = fetchTarball {
    url = "https://github.com/starfive-tech/soft_3rdpart/raw/refs/heads/JH7110_VisionFive2_devel/IMG_GPU/out/img-gpu-powervr-bin-1.19.6345021.tar.gz";
    sha256 = "sha256:0ha8wjhyvjsq11156lifqd60yckaf7yvmm9fg18cvnnsj2i3bazc";
  };
  installPhase = ''
    mkdir -p $out/etc
    mkdir -p $out/lib
    mkdir -p $out/usr
    cp -r target/etc/* $out/etc/
    cp -r target/lib/* $out/lib/
    cp -r target/usr/* $out/usr/
  '';
})
