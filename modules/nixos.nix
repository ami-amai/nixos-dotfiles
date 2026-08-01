{ pkgs, throne-nixpkgs, config, ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs config throne-nixpkgs; };

in

{
  
  system = {
    stateVersion = cfg.nixos.stateVersion;
  };

  nix.settings = {
    experimental-features = cfg.nixos.experimentalFeatures;
  };
  nixpkgs.config = {
    allowUnfree = cfg.nixos.unfreePkgs;
  };

}