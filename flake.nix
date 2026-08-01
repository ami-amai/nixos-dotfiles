{

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    throne-nixpkgs.url =
      "github:TomaSajt/nixpkgs/63d18e3bacc2f7009795b014f5a3067303180027";

  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      throne-nixpkgs,
      pkgs,
      ...
    }:

    let

      cfg = import ( ../cfg.nix ) { inherit pkgs; };

    in
    {
      nixosConfigurations."${cfg.nixos.stateVersion}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./imports.nix

          home-manager.nixosModules.home-manager
        ];
      };
    };
}