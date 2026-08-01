{ home-manager, ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

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