{ pkgs, throne-nixpkgs, config, ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs throne-nixpkgs config; };

in

{

  boot = cfg.boot;

}