{ ... }:

let

  cfg = import ( ../cfg.nix );

in

{
  programs = cfg.programs;
}