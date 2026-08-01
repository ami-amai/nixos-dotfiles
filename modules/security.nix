{ ... }:

let

  cfg = import ( ../cfg.nix );

in

{
  security = cfg.security;
}