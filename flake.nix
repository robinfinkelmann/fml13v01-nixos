{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "git+https://github.com/hercules-ci/flake-parts";

  # Vendor repos
  inputs.uboot = {
    url = "github:DC-DeepComputing/fml13v01-uboot/fm7110-6.6";
    flake = false;
  };
  inputs.opensbi = {
    url = "github:DC-DeepComputing/fml13v01-opensbi/fm7110-6.6";
    flake = false;
  };
  inputs.linux = {
    url = "github:DC-DeepComputing/fml13v01-linux/3032df5dfbfff37a40a9433c3bb8f8ea891d30ba";
    flake = false;
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-hardware,
      flake-parts,
      uboot,
      opensbi,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; }(
       top@{
        config,
        withSystem,
        moduleWithSystem,
        ...
      }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "riscv64-linux"
        ];
        perSystem = { config, pkgs, self', ... }: {
          packages = rec{
            default = sdImage;
            inherit (self.nixosConfigurations.fml13v01.config.system.build) sdImage;
          };
          formatter = pkgs.nixfmt-tree;
        };
        flake = {
          hydraJobs = {
            inherit (self) packages;
          };
        # TODO split this into a NixOS module and an example config
        nixosConfigurations = rec {
          default = fml13v01;
          fml13v01 = nixpkgs.lib.nixosSystem rec {
            specialArgs = {
              inherit inputs;
            };
            system = "x86_64-linux"; # TODO dont hardcode this
            modules = [
              (
                {
                  config,
                  lib,
                  pkgs,
                  ...
                }:
                {
                  imports = [
                    (./. + "/fml13v01/sd-image-installer.nix")
                    # Use the following import if using a separate NixOS config
                    # "${fml13v01-nixos}/fml13v01/sd-image-installer.nix"
                  ];

                  # Modify the module's options
                  hardware.fml13v01.uboot.src = inputs.uboot;
                  hardware.fml13v01.uboot.patches = [ ];
                  #hardware.fml13v01.linux.vendorKernel = true;

                  users.users.nixos.password = "test123";

                  nix.settings.experimental-features = [
                    "nix-command"
                    "flakes"
                  ];
                  nixpkgs.config.allowUnfree = true;
                  nix.package = pkgs.lix;

                  environment.systemPackages = with pkgs; [
                    util-linux
                    btop
                    htop
                    fastfetch
                    sl
                    #cmatrix
                    #asciiquarium
                    cowsay
                    nmap
                    tmux
                    dua
                    duf
                    git
                  ];

                  sdImage.compressImage = false;

                  nixpkgs.crossSystem = {
                    config = "riscv64-unknown-linux-gnu";
                    system = "riscv64-linux";
                  };

                  system.stateVersion = "25.05";
                }
              )
            ];
          };
        };
    };
  });
}
