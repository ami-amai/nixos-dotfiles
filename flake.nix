{
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    ...
  }:

  let 

  system = "x86_64-linux";

  pkgs = nixpkgs.legacyPackages.${system};

  pkgsU = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };

  cfg = import ./configuration.nix {
    inherit pkgs pkgsU;
    lib = nixpkgs.lib;
    config = {
      hardware.enableRedistributableFirmware = true;
    };
  };
  
  in 
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      
      # Platform
      system = system;

      # Special Arguments
      specialArgs = {
        inherit pkgsU cfg;
      };

      # Modules
      modules = [
        ## Home Manager
        home-manager.nixosModules.home-manager

        ## Programs and services
        ./programs.nix
        ./services.nix

        ## Config modules
        ./modules/nixos.nix
        ./modules/system.nix
        ./modules/user.nix

        ## Sound module
        ./modules/sound/pipewire.nix

        ## Program modules
        ./modules/program/steam.nix
        ./modules/program/thunar.nix
      ];
    };
  };
}