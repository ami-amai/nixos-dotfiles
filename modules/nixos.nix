{ pkgs, ... }:

let

  ROOT = /etc/nixos;
  nix_config = import ("${ROOT}/config.nix") { inherit pkgs; };

in

{

  # NixOS settings
  system.stateVersion = nix_config.nixos.version; # Did you read the comment?
  nix.settings.experimental-features = nix_config.nixos.experimental-features;
  nixpkgs.config.allowUnfree = nix_config.nixos.unfreePkgs;

}