{ pkgs, ... }:

{

  nixos = {
    version = "26.05";
    unfreePkgs = true;
    features = [
      "nix-command"
      "flakes"
    ];
  };

  user = {
    name = "ami";
    shell = pkgs.zsh;
    groups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; []
    ++ [ vscode direnv ] # vscode
    ++ [ krita xppen_4 ] # krita
    ++ [ prismlauncher ] # minecraft
    ++ [ chromium ] # browser
    ++ [ telegram-desktop discord ] # socials
    ++ [
      gamemode
      openblas
    ];
  };

  environment = {
    timezone = "Europe/Moscow";
    layout = {
      default = "us";
      extra = "ru";
    };
    locale = {
      default = "en_US";
      extra = "ru_RU";
    };
    displayManager = "ly";
    packages = with pkgs; []
    ++ [ kitty awww hyprshot hyprpolkitagent ] # Extra hyprland
    ++ [ mc htop bluetuith wiremix alsa-utils ] # TUI utils
    ++ [ mtpfs ntfs3g ] # Extra fs types
    ++ [
      fastfetch
      rofi # Launcher
    ];
    programs = []
    ++ [ "hyprland" "hyprland.xwayland" ] # Hyprland
    ++ [ "throne" "throne.tunMode" ] # Throne
    ++ [ "thunar" "xfconf" ] # FileManager
    ++ [
      "zsh"
      "git"
      "steam"
    ];
    services = []
    ++ [ "pipewire" "pipewire.alsa" "pipewire.pulse" ] # Pipewire
    ++ [ "gvfs" "tumbler" ] # Thunar
    ++ [];
  };
}