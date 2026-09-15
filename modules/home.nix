{ cfg, ... }:


{

  # HOME
  home-manager = {
    users.${cfg.USER.name} = {
    	home.stateVersion = cfg.NIXOS.stateVersion;
        home.file = cfg.HOME.symlinks;
        home.package = cfg.HOME.packages;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # HOME
  #home = {
  #  stateVersion = "${cfg.NIXOS.stateVersion}";
  #  file = cfg.HOME.imports;
  #  packages = cfg.HOME.packages; 
  #};

}
