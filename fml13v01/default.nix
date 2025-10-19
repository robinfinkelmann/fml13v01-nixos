{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.hardware.fml13v01;
in
{
  imports = [
    ./firmware.nix
  ];

  options = {
    hardware.fml13v01 = {
      linux = {
        vendorKernel = lib.mkOption {
          description = "(EXPERIMENTAL) Use the vendor linux kernel including GPU packages";
          type = lib.types.bool;
          default = false;
        };
      };
    };
  };

  config = lib.mkMerge [
    ({
      boot = {
        consoleLogLevel = lib.mkDefault 7;

        # TODO this was copied, probably unneccessary
        initrd.availableKernelModules = [ "dw_mmc_starfive" ];
        # Support booting SD-image from NVME SSD
        initrd.kernelModules = [
          "clk-starfive-jh7110-aon"
          "clk-starfive-jh7110-stg"
          "phy-jh7110-pcie"
          "pcie-starfive"
          "nvme"
        ];

        loader = {
          grub.enable = lib.mkDefault false;
          generic-extlinux-compatible.enable = lib.mkDefault true;
        };

        # Use the latest kernel by default
        kernelPackages = pkgs.linuxPackages_latest;
      };

      # Boot from the respective .dtb (this sets FDTFILE in the uboot env)
      hardware.deviceTree = {
        name = "starfive/jh7110-deepcomputing-fml13v01.dtb";
        # dtbSource
      };
    })

    # TODO Attempt at enabling GPU drivers, not working atm
    (lib.mkIf cfg.linux.vendorKernel {
      boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (
        pkgs.linuxKernel.kernels.linux_6_6.override {
          argsOverride = rec {
            src = inputs.linux;
            version = "6.6.20";
            modDirVersion = "6.6.20";
            #defconfig = "${inputs.linux}/arch/riscv/configs/fml13v01_defconfig";
            defconfig = "fml13v01_defconfig";
            kernelArch = "riscv";
          };
        }
      ));
      hardware.graphics.package = config.system.build.mesa;
      hardware.graphics.extraPackages = [
        config.system.build.gpu
      ];
      environment.etc = {
        "OpenCL/vendors/IMG.icd" = {
          source = "${config.system.build.gpu}/etc/OpenCL/vendors/IMG.icd";
        };
        "vulkan/icd.d/idconf.json" = {
          source = "${config.system.build.gpu}/etc/vulkan/icd.d/idconf.json";
        };
      };
      services.udev.extraRules = ''
        ENV{DEVNAME}=="/dev/dri/card1", TAG+="mutter-device-preferred-primary"
      '';
      services.xserver.config = lib.mkAfter ''
        Section "OutputClass"
        Identifier "Starfive Display"
        MatchDriver "starfive"
        Driver "modesetting"
        Option "PrimaryGPU" "true"
        #Option "AccelMethod" "no"
        Option "SWcursor" "false"
        Option "NoCursor" "true"
        Option "ShadowFB" "true"
        Option "Atomic" "true"
        Option "DoubleShadow" "true"
        Option "PageFlip" "true"
        Option "VariableRefresh" "true"
        Option "AsyncFlipSecondaries" "true"
        EndSection
        #Section "Extensions"
        #Option "glx" "Disable"
        #Option "Composite" "Disable"
        #EndSection
      '';
      environment.variables = {
        COGL_DRIVER = "gles2";
        GST_GL_API = "gles2";
        CLUTTER_PAINT = "disable-clipped-redraws";
        XWAYLAND_NO_GLAMOR = 1;
        SDL_VIDEODRIVER = "wayland";
        MESA_LOADER_DRIVER_OVERRIDE = "pvr";
      };
      boot.blacklistedKernelModules = [
        "starfive_mailbox_test"
        "e24"
        "xrp"
        "starfive_mailbox"
        "wave5"
        "evbug"
      ];
    })
  ];
}
