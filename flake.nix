{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

  # Some dependencies of this flake are not yet available on non linux systems
  inputs.systems.url = "github:nix-systems/x86_64-linux";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-utils.inputs.systems.follows = "systems";

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
    {
      self,
      nixpkgs,
      nixos-hardware,
      flake-utils,
      uboot,
      opensbi,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgsCross = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "riscv64-unknown-linux-gnu";
            system = "riscv64-linux";
          };
        };
      in
      rec {
        packages = {
          default = packages.sdImage;
        }
        // self.outputs.nixosConfigurations.fml13v01.config.system.build;
        formatter = pkgs.nixfmt-tree;
      }
    )
    // {
      # TODO split this into a NixOS module and an example config
      nixosConfigurations = {
        default = self.outputs.nixosConfigurations.fml13v01;
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
                  neofetch
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
}
