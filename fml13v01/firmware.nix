{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.hardware.fml13v01;
in
{
  options = {
    hardware.fml13v01 = {
      opensbi = {
        src = lib.mkOption {
          description = "OpenSBI source";
          type = lib.types.nullOr lib.types.package;
          default = null;
        };
        patches = lib.mkOption {
          description = "List of patches to apply to the OpenSBI source";
          type = lib.types.nullOr (lib.types.listOf lib.types.package);
          default = null;
        };
      };
      uboot = {
        src = lib.mkOption {
          description = "U-boot source";
          type = lib.types.nullOr lib.types.package;
          default = null;
        };
        patches = lib.mkOption {
          description = "List of patches to apply to the U-boot source";
          type = lib.types.nullOr (lib.types.listOf lib.types.package);
          default = null;
        };
      };
    };
  };

  config = {
    system.build = rec {
      spl-tool = pkgs.buildPackages.callPackage ./spl-tool.nix { }; # TODO specifying buildPackages here is dodgy, it should not be neccessary but was?!?
      its-file = pkgs.writeText "deepcomputing-fml13v01" ''
        /dts-v1/;

        / {
          description = "U-boot-spl FIT image for JH7110 fml13v01";
          #address-cells = <2>;

          images {
            firmware {
              description = "u-boot";
              data = /incbin/("${opensbi}/share/opensbi/lp64/generic/firmware/fw_payload.bin");
              type = "firmware";
              arch = "riscv";
              os = "u-boot";
              load = <0x0 0x40000000>;
              entry = <0x0 0x40000000>;
              compression = "none";
            };
          };

          configurations {
            default = "config-1";

            config-1 {
              description = "U-boot-spl FIT config for JH7110 fml13v01";
              firmware = "firmware";
            };
          };
        };
      '';
      opensbi =
        (pkgs.callPackage ./opensbi.nix {
          withPayload = "${uboot}/u-boot.bin";
          withFDT = "${uboot}/starfive_visionfive2.dtb";
        }).overrideAttrs
          (
            _f: p: {
              src = if cfg.opensbi.src != null then cfg.opensbi.src else p.src;
              patches = if cfg.opensbi.patches != null then cfg.opensbi.patches else (p.patches or [ ]);
            }
          );

      uboot = (pkgs.callPackage ./uboot.nix { inherit (config.system.build) opensbi; }).overrideAttrs (
        _f: p: {
          src = if cfg.uboot.src != null then cfg.uboot.src else p.src;
          patches = if cfg.uboot.patches != null then cfg.uboot.patches else (p.patches or [ ]);
        }
      );
      #uboot = pkgs.ubootVisionFive2;
      spl = pkgs.stdenv.mkDerivation {
        name = "deepcomputing-fml13v01-spl";
        depsBuildBuild = [ spl-tool ];
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out/share/deepcomputing-fml13v01/
          ln -s ${uboot}/u-boot-spl.bin .
          spl_tool -c -f ./u-boot-spl.bin
          cp u-boot-spl.bin.normal.out $out/share/deepcomputing-fml13v01/spl.bin
        '';
      };
      uboot-fit-image = pkgs.stdenv.mkDerivation {
        name = "deepcomputing-fml13v01-uboot-fit-image";
        nativeBuildInputs = [ pkgs.dtc ];
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out/share/deepcomputing-fml13v01/
          ${uboot}/mkimage -f ${its-file} -A riscv -O u-boot -T firmware $out/share/deepcomputing-fml13v01/fml13v01_fw_payload.img
        '';
        extraMakeFlags = [
          "OPENSBI=${opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin"
        ];
      };
      updater-flash = pkgs.writeShellApplication {
        name = "deepcomputing-fml13v01-firmware-update-flash";
        runtimeInputs = [ pkgs.mtdutils ];
        text = ''
          flashcp -v ${spl}/share/deepcomputing-fml13v01/spl.bin /dev/mtd0
          flashcp -v ${uboot-fit-image}/share/deepcomputing-fml13v01/fml13v01_fw_payload.img /dev/mtd2
        '';
      };
      updater-sd = pkgs.writeShellApplication {
        name = "deepcomputing-fml13v01-firmware-update-sd";
        runtimeInputs = [ ];
        text = ''
          dd if=${spl}/share/deepcomputing-fml13v01/spl.bin of=/dev/mmcblk0p1 conv=fsync
          dd if=${uboot-fit-image}/share/deepcomputing-fml13v01/fml13v01_fw_payload.img of=/dev/mmcblk0p2 conv=fsync
        '';
      };
      gpu = pkgs.callPackage ./gpu.nix { };
      mesa = pkgs.callPackage ./mesa.nix { };
    };
  };
}
