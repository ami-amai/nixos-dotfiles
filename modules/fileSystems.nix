{ pkgs, throne-nixpkgs, config, ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs config throne-nixpkgs; };

in

{

  fileSystems = cfg.fileSystems;

}