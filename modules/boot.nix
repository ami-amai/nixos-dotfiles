{ ... }:

let

  cfg = import ( ../cfg.nix );

in

{

  boot = cfg.boot;

}