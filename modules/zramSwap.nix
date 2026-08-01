{ ... }:

let

  cfg = import ( ../cfg.nix );

in

{

  zramSwap = cfg.zramSwap;

}