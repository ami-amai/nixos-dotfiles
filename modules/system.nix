{ pkgs, ... }:

let

  ROOT = /etc/nixos;
  nix_config = import ("${ROOT}/config.nix") { inherit pkgs; };

in

{

    # Network and hostname
  networking = {
    hostName = nix_config.system.hostname; # Define your hostname
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = nix_config.system.timezone;

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "${nix_config.system.locale.default}.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "${nix_config.system.locale.extra}.UTF-8";
      LC_IDENTIFICATION = "${nix_config.system.locale.extra}.UTF-8";
      LC_MEASUREMENT = "${nix_config.system.locale.extra}.UTF-8";
      LC_MONETARY = "${nix_config.system.locale.extra}.UTF-8";
      LC_NAME = "${nix_config.system.locale.extra}.UTF-8";
      LC_NUMERIC = "${nix_config.system.locale.extra}.UTF-8";
      LC_PAPER = "${nix_config.system.locale.extra}.UTF-8";
      LC_TELEPHONE = "${nix_config.system.locale.extra}.UTF-8";
      LC_TIME = "${nix_config.system.locale.extra}.UTF-8";
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = nix_config.system.layout.default;
    variant = nix_config.system.layout.variants;
  };

  # Kernel
  boot.kernelPackages = nix_config.system.kernel;

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

}