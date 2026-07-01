{ pkgs, ... }:

let

  ROOT = /etc/nixos;
  nix_config = import ("${ROOT}/config.nix") { inherit pkgs; };

  home = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-${nix_config.nixos.version}.tar.gz";

in

{

  imports = 
    if
      nix_config.home.enable == true
    then
      [ (import "${home}/nixos") ]
    else 
      [];

  home-manager.users.${nix_config.user.name}.home.stateVersion = nix_config.nixos.version;

}
