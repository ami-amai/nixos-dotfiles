{ pkgs, config, lib ... }:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

in

{
  # Timezone
  time.timeZone = cfg.system.timeZone;

  # Locale
    i18n = {
    defaultLocale = "${cfg.system.locale.default}.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "${cfg.system.locale.extra}.UTF-8";
      LC_IDENTIFICATION = "${cfg.system.locale.extra}.UTF-8";
      LC_MEASUREMENT = "${cfg.system.locale.extra}.UTF-8";
      LC_MONETARY = "${cfg.system.locale.extra}.UTF-8";
      LC_NAME = "${cfg.system.locale.extra}.UTF-8";
      LC_NUMERIC = "${cfg.system.locale.extra}.UTF-8";
      LC_PAPER = "${cfg.system.locale.extra}.UTF-8";
      LC_TELEPHONE = "${cfg.system.locale.extra}.UTF-8";
      LC_TIME = "${cfg.system.locale.extra}.UTF-8";
    };
  };


  # Services
  services = lib.mkMerge (
    [
      {
        # Layout
        xserver.xkb = {
          layout = cfg.system.layout.default;
          variant = cfg.system.layout.extra;
        };

        # Display Manager
        displayManager.${cfg.system.displayManager}.enable = true;
      }
    ]
    #++ map enable cfg.environment.services
  );

  # Packages
  environment.systemPackages = cfg.system.environmentPackages;

  # Networking
  networking = {

    ## HostName
    hostName = cfg.hostName;

    ## Network Manager
    networkmanager.enable = cfg.networkManager;
  };

  # Hardware
  hardware = {

    ## Bluetooth
    bluetooth = {
      enable = true;
    };

    ## AMD
    cpu.amd = {
      updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      ryzen-smu.enable = true;
    };

    enableRedistributableFirmware = true;
    
  };
}