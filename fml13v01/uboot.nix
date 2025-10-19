{
  buildUBoot,
  opensbi,
}:

let
  replacementImage = ./logo.bmp;
in
buildUBoot {
  #extraMakeFlags = [
  #  "OPENSBI=${opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin"
  #];

  # TODO this should no longer be neccessary, test pls!
  extraConfig = ''
    CONFIG_DEFAULT_FDT_FILE=starfive/jh7110-deepcomputing-fml13v01.dtb
  '';

  defconfig = "starfive_visionfive2_defconfig";

  # Working with professional code here ;)
  NIX_CFLAGS_COMPILE = "-Wno-int-conversion -Wno-implicit-function-declaration";

  filesToInstall = [
    "u-boot.bin"
    "arch/riscv/dts/starfive_visionfive2.dtb"
    "spl/u-boot-spl.bin"
    "tools/mkimage"
  ];
}
