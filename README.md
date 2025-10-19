# About

This repo attempts to port NixOS to the [first generation RiscV board by DeepComputing for the Framework 13 laptop](https://deepcomputing.io/product/dc-roma-risc-v-mainboard/) (known as fml13v01).

# What works

- [x] Cross-compilation
- [x] Native compilation
- [x] Linux 6.17 from nixpkgs (some hardware support missing, i.e. GPU and VPU drivers)
- [ ] Vendor's Linux 6.6.20 (does not compile)
- [x] Vendor's u-boot (even with graphics!)
- [ ] u-boot from nixpkgs (compiles and launches, but does not boot)
- [ ] edk2 (not yet attempted)
- [ ] GPU drivers
- [ ] VPU drivers
- [x] Network
- [x] Nix
- [x] NixOS
- [x] Many nixpkgs

## Compilation

As native performance of the fml13v01's CPU is sub-par, this repo cross-compiles from x86_64-linux by default. For first boot, building an sd image is required. For subsequent updates, using a remote building / deployment configuration via SSH is recommended.

## Kernel

For now, the port only works with the latest upstream linux kernel. This, however, does not contain GPU or VPU drivers, therefore no display output is active.

An effort is ongoing to compile the vendor's 6.6.20 linux kernel.

## U-Boot

For now, the port only works with the vendor's u-boot environment. The upstream u-boot does compile and start, and should support the hardware, however it can by default not boot into NixOS successfully. This is due to sysboot not being available in the u-boot environment. Adapting the u-boot derivation or switching to a different boot mechanism might work, and would be desirable.

## OpenSBI

There was no apparent difference between usig the upstream or the vendor's OpenSBI, which is why the upstream OpenSBI is chosen. In contrast to nixos-hardware's VisionFive-v2 port, we package OpenSBI with a payload of u-boot, instead of the other way around (at least that's how I understand it).

# Usage

As this project is still quite unstable and early in development, I recommend cloning / forking and adjusting stuff to your needs from there. 

## Using this flake standalone:

Clone the repo on an x86_64-linux host, then build the sd image:
``` sh
nix build .
```

The resulting image can then be copied to an sd card:
``` sh
dd if=result/sd-image/<name>.img /dev/<sd-blockdevice> status=progress
```

The board should successfully boot into NixOS when powered on. The first boot might take a couple extra minutes, when resizing the filesystem to fit the sd card.

For now, there is no display output after the u-boot process. However, network should be available, allowing you to use ssh to connect.

If you need a serial connection, follow [the guide by DeepComputing](https://github.com/DC-DeepComputing/Framework/blob/85b53e6f7c54f283e7e60f45de176fe9ab495bde/FML13V01/Framework%20Serial%20Port%20Connection%20Guide.pdf). Note that you need a USB-C cable that supports side-band-use (SBU), e.g. DisplayPort Alt Mode or Thunderbolt. When in doubt, check the cable for continuity on SBU1/2 using two USB-C breakout boards. Also note that you might need to rotate the USB-C cable for success, depending on the type of breakout board you use (ironic, I know).

## Using this flake as a NixOS module:

TODO

## Impoorting this flake into a seperate flake's NixOS config

Warning: This setup is not tested by me!

Import this repo into your flake:
``` nix
{
    inputs.fml13v01-nixos = {
        url = "github:robinfinkelmann/fml13v01-nixos";
        inputs.nixpkg.follows = "nixpkgs";
    };
}
```

Copy the NixOS config from this repo into your own flake, and adjust the import:
``` nix
{ config, ... }: {
    imports = [
    "${fml13v01-nixos}/fml13v01/sd-image-installer.nix"
    ];

    # Rest of the config
};
```

Provide a package for the sd image:
``` nix
{
    outputs.packages.x86_64-linux.fml13v01-sdImage = self.outputs.nixosConfigurations.fml13v01.config.system.build.sdImage;
}
```

Then build the sd image:
``` sh
nix build .#fml13v01-sdImage
```

# Structure

- [flake.nix](flake.nix)
    - `nicosConfigurations.fml13v01` (as generic as possible)
    - `packages.sdImage`
    - `packages.<name>` (all packages defined in config.system.build in [firmware.nix](fml13v01/firmware.nix))
- [fml13v01](fml13v01)
    - [default.nix](fml13v01/default.nix): NixOS configuration
    - [firmware.nix](fml13v01/firmware.nix): custom NixOS options and packages
    - [sd-image.nix](fml13v01/sd-image.nix), [sd-image-installer.nix](fml13v01/sd-image-installer.nix): creating the sd image
    - [uboot.nix](fml13v01/uboot.nix), [spl-tool.nix](fml13v01/spl-tool.nix), [opensbi.nix](fml13v01/opensbi.nix), [gpu.nix](fml13v01/gpu.nix), [mesa.nix](fml13v01/mesa.nix): packages with callPackage syntax 

# Useful references

- https://deepcomputing.io/product/dc-roma-risc-v-mainboard/
- https://github.com/DC-DeepComputing/fml13v01
- https://doc-en.rvspace.org/Doc_Center/visionfive_2.html
- https://docs.u-boot.org/en/latest/board/starfive/deepcomputing_fml13v01.html
- https://github.com/NixOS/nixos-hardware/tree/master/starfive/visionfive/v2
- https://github.com/NixOS/nixos-hardware/tree/master/pine64/star64
- https://github.com/starfive-tech/Debian/releases
- https://wiki.debian.org/InstallingDebianOn/FrameWork/Laptop13/DeepComputing_RISC-V_V1
- https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/loader/generic-extlinux-compatible/default.nix
- https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/graphics.nix
- https://github.com/NixOS/nixpkgs/blob/master/pkgs/misc/uboot/default.nix