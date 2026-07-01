{ config, pkgs, ... }:

let

  ROOT = /etc/nixos;
  nix_config = import ("${ROOT}/config.nix") { inherit pkgs; };

in

{

  imports = [];

  users.users.${nix_config.user.name} = {
    isNormalUser = true;
    shell = nix_config.user.shell;
    description = nix_config.user.name;
    extraGroups = nix_config.user.groups;
    packages = with pkgs; []
    ++ nix_config.user.packages;
  };

  system.activationScripts.nixosConfigPermissions.text = ''
    chown -R ${nix_config.user.name}:users /etc/nixos
    chmod -R u+rwX,go-w /etc/nixos
  '';
}