{ ... }:

let

  cfg = import ( ../cfg.nix );

in

{

  fileSystems = cfg.fileSystems;

}