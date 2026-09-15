{ cfg, ... }:

{

  # NIXOS
  system.stateVersion = cfg.NIXOS.stateVersion;
  nixpkgs.config.allowUnfree = cfg.NIXOS.allowUnfree;
  nix.settings.experimental-features = cfg.NIXOS.experimentalFeatures;
  
}