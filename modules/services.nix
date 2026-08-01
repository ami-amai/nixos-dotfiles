{ ... }:

let

  cfg = import ( ../cfg.nix );

in

{
  services = cfg.services;
}