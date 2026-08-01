{ pkgs, throne-nixpkgs, config, ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs config throne-nixpkgs; };


in

{

  zramSwap = cfg.zramSwap;

}