{ pkgs, throne-nixpkgs, config, home-manager, ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs config throne-nixpkgs; };

in

{
  
  home = {
    stateVersion = "${cfg.nixos.releaseVersion}";
    file = cfg.home.files;
  };

  home-manager = {

    useGlobalPkgs = true;
    useUserPackages = true;

  };

}