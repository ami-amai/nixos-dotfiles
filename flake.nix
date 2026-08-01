{

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    throne-nixpkgs.url =
      "github:TomaSajt/nixpkgs/63d18e3bacc2f7009795b014f5a3067303180027";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      throne-nixpkgs,
      ...
    }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./configuration.nix
        ];
      };
    };
}