{ ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

in

{
  security = cfg.security;
}