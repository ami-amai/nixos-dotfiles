{ pkgs, ... }:

let

  ROOT = /etc/nixos;
  nix_config = import ("${ROOT}/config.nix") { inherit pkgs; };

in

{

  imports = [];

  # Display Manager
  services.displayManager.${nix_config.environment.display-manager}.enable = true;

  # Environment packages
  environment.systemPackages = nix_config.environment.packages;
}