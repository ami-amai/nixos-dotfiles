{}:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

in

{

  boot = cfg.boot;

}