{ pkgs, ... }:

{
  # MODULES
  modules = [
    "system"
    "nixos"
    "home"
    "user"
    "programs"
    "services"
    "environment"
  ];

  # NIXOS
  nixos = {
    version = "26.05";
    unfreePkgs = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # SYSTEM
  system = {
    hostname = "nixos";
    kernel = pkgs.linuxPackages_latest;
    timezone = "Europe/Moscow";
    layout = {
      default = "us";
      variants = "";
    };
    locale = {
      default = "en_US";
      extra = "ru_RU";
    };
  };

  # ENVIRONMENT
  environment = {
    display-manager = "ly";
    packages = with pkgs; [

      # TERMINAL
      kitty

      # HYPRLAND
      hyprland # 
      hyprshot # screenshots
      awww # wallpapers
      hyprpolkitagent

      # APPLICATION MENU
      rofi

      # UTILS
      mc
      htop
      fastfetch
      bluetuith
      wiremix
      alsa-utils

    ];
    programs = [
      # HYPRLAND
      "hyprland"
      "hyprland.xwayland"

      # VPN
      "throne"
      "throne.tunMode"

      # STEAM
      "steam"

      # THUNAR
      "thunar"
      "xfconf"

      # ZSH
      "zsh"

      # UTILS
      "git"
    ];
    services = [

      # SOUNDS
      "pipewire"
      "pipewire.alsa"
      "pipewire.pulse"

      # THUNAR
      "gvfs"
      "tumbler"

      # SSH
      "openssh"
    ];
  };

  # USER
  user = {
    name = "ami";
    shell = pkgs.zsh;
    groups = [
      "networkmanager"
      "wheel"
    ];
    openssh-keys = [
    ];
    packages = with pkgs; [
      
      # VSCODE
      vscode
      direnv

      # KRITA
      krita
      openblas
      xppen_4

      # MINECRAFT
      prismlauncher

      # BROWSER
      chromium

      # SOCIAL
      telegram-desktop
      discord
    ];
  };

  # HOME
  home = {
    enable = true;
  };

}