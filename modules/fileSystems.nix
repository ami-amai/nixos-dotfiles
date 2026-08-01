{}:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

in

{

  fileSystems = cfg.fileSystems;

}