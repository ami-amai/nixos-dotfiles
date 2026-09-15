{ cfg, ... }:


{

  # HOME
  home-manager = {
    users.${cfg.USER.name} = import ./home.nix;
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # HOME
  home = {
    stateVersion = "${cfg.NIXOS.stateVersion}";
    file = cfg.HOME.imports;
    packages = cfg.HOME.packages; 
  };

}