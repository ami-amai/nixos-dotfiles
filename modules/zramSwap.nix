{}:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

in

{

  zramSwap = cfg.zramSwap;

}