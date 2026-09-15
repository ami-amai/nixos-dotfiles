{ cfg, ... }:

{



  # FILESYSTEM
  fileSystems = cfg.FILESYSTEM;

  # HARDWARE
  hardware = cfg.HARDWARE;

  # BOOT
  boot = {
    # KERNEL
    kernelPackages = cfg.KERNEL.packages;
    kernelModules = cfg.KERNEL.modules;
    kernelParams = cfg.KERNEL.params;
    extraModulePackages = cfg.KERNEL.extraModules;

    # BOOT
    initrd = cfg.BOOT.initrd;
    loader = cfg.BOOT.loader;
  };

  # ZRAMSWAP
  zramSwap = cfg.ZRAMSWAP;

  # ENVIRONMENT
  time.timeZone = cfg.ENVIRONMENT.timeZone;
  i18n = {
    defaultLocale = "${cfg.ENVIRONMENT.locale.default}.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "${cfg.ENVIRONMENT.locale.extra}.UTF-8";
      LC_IDENTIFICATION = "${cfg.ENVIRONMENT.locale.extra}.UTF-8";
      LC_MEASUREMENT = "${cfg.ENVIRONMENT.locale.extra}.UTF-8";
      LC_MONETARY = "${cfg.ENVIRONMENT.locale.extra}.UTF-8";
      LC_NAME = "${cfg.ENVIRONMENT.locale.extra}.UTF-8";
      LC_NUMERIC = "${cfg.ENVIRONMENT.locale.extra}.UTF-8";
      LC_PAPER = "${cfg.ENVIRONMENT.locale.extra}.UTF-8";
      LC_TELEPHONE = "${cfg.ENVIRONMENT.locale.extra}.UTF-8";
      LC_TIME = "${cfg.ENVIRONMENT.locale.extra}.UTF-8";
    };
  };

  services = {
    xserver.xkb = {
      layout = cfg.ENVIRONMENT.layout.default;
      variant = cfg.ENVIRONMENT.layout.extra;
    };
    displayManager.${cfg.ENVIRONMENT.displayManager}.enable = true;
  };

  networking = {
    hostName = cfg.HOSTNAME;
    networkmanager.enable = cfg.ENVIRONMENT.networkManager;
  };

  environment.systemPackages = cfg.ENVIRONMENT.packages;
  
}