{ pkgs, home-manager, ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

  MODULES = [

    ## Hardware
    "boot"
    "fileSystems"

    ## System Software
    "system"
    "zramSwap"
    "nixos"

    ## User Software
    "user"
    "programs"
    "services"
    "security"
  ];

in

{
  imports = map (module: ./modules/${module}.nix) MODULES;

  home-manager.users.${cfg.user.name} = import ./modules/home.nix

}