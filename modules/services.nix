{ ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

in

{
  services = cfg.services;
}