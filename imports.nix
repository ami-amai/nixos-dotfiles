{ pkgs, throne-nixpkgs, config, home-manager, ... }:

let

  cfg = import ( ./cfg.nix ) { inherit pkgs config throne-nixpkgs; };

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

  home-manager = {

    ## Home Manager User
    users.${cfg.user.name} = import ./modules/home.nix;

    ## Home Manager Settings
    useGlobalPkgs = true;
    useUserPackages = true;
  };

}