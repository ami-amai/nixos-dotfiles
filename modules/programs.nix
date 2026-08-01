{ ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

in

{
  programs = cfg.programs;
}