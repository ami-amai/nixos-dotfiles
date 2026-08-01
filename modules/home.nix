{ pkgs, throne-nixpkgs, config, home-manager, ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs config throne-nixpkgs; };

in

{
  
  home = {
    stateVersion = "${cfg.nixos.stateVersion}";
    file = cfg.home.files;
  };

}