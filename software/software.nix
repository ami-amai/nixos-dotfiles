{ pkgs, lib, ... }:

let

  ROOT = ./..;
  cfg = import (ROOT + "/software.nix") { inherit pkgs; };

  importPrograms =
    builtins.filter builtins.pathExists
      (map (program: ./programs + "/${program}.nix") cfg.environment.programs);

  importServices =
    builtins.filter builtins.pathExists
      (map (service: ./services + "/${service}.nix") cfg.environment.services);


  enable = object:
    lib.setAttrByPath
      ((lib.splitString "." object) ++ [ "enable" ]) true;

in

{
  # IMPORTS
  imports = []

  # Home manager
  ++ [ (import "${(builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-${cfg.nixos.version}.tar.gz")}/nixos") ]
  
  # Programs and Services
  ++ importPrograms
  ++ importServices;

  # USER
  users.users.${cfg.user.name} = {
    isNormalUser = true;
    shell = cfg.user.shell;
    description = "normal user";
    extraGroups = cfg.user.groups;
    packages = with pkgs; []
    ++ cfg.user.packages;
  };

  # Polkit Agent
  security.polkit.enable = cfg.user.polkitAgent;

  # HOME MANAGER
  home-manager.users.${cfg.user.name} = {
    home.stateVersion = cfg.nixos.version;
  };

  # NIXOS
  system.stateVersion = cfg.nixos.version;
  nix.settings.experimental-features = cfg.nixos.features;
  nixpkgs.config.allowUnfree = cfg.nixos.unfreePkgs;

  # ENVIRONMENT

  # Timezone
  time.timeZone = cfg.environment.timezone;

  # Locale
    i18n = {
    defaultLocale = "${cfg.environment.locale.default}.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "${cfg.environment.locale.extra}.UTF-8";
      LC_IDENTIFICATION = "${cfg.environment.locale.extra}.UTF-8";
      LC_MEASUREMENT = "${cfg.environment.locale.extra}.UTF-8";
      LC_MONETARY = "${cfg.environment.locale.extra}.UTF-8";
      LC_NAME = "${cfg.environment.locale.extra}.UTF-8";
      LC_NUMERIC = "${cfg.environment.locale.extra}.UTF-8";
      LC_PAPER = "${cfg.environment.locale.extra}.UTF-8";
      LC_TELEPHONE = "${cfg.environment.locale.extra}.UTF-8";
      LC_TIME = "${cfg.environment.locale.extra}.UTF-8";
    };
  };


  # Services
  services = lib.mkMerge (
    [
      {
        # Layout
        xserver.xkb = {
          layout = cfg.environment.layout.default;
          variant = cfg.environment.layout.extra;
        };

        # Display Manager
        displayManager.${cfg.environment.displayManager}.enable = true;
      }
    ]
    # 
    ++ map enable cfg.environment.services
  );

  # Packages
  environment.systemPackages = cfg.environment.packages;

  # Programs
  programs = lib.mkMerge (map enable cfg.environment.programs);
}
