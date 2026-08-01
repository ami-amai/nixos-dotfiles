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
    polkitAgent = true;
    packages = with pkgs; []
    ++ [ vscode direnv ] # vscode
    ++ [ krita xppen_4 ] # krita
    ++ [ prismlauncher ] # minecraft
    ++ [ chromium firefox ] # browser
    ++ [ telegram-desktop discord ] # socials
    ++ [ mangohud protonup-qt protontricks vulkan-tools mesa-demos ] # Steam
    ++ [
      nodejs
      mpv
      gamemode
      openblas
      android-tools
      spotify
      blockbench
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
      ryzenadj
      fastfetch
      rofi # Launcher
    ];
    programs = []
    ++ [ "hyprland" "hyprland.xwayland" ] # Hyprland
    ++ [ "throne" "throne.tunMode" ] # Throne
    ++ [ "thunar" "xfconf" ] # FileManager
    ++ [ "steam" "gamemode" "gamescope" ] # Steam
    ++ [
      "zsh"
      "git"
    ];
    services = []
    ++ [ "pipewire" "pipewire.alsa" "pipewire.pulse" ] # Pipewire
    ++ [ "gvfs" "tumbler" ] # Thunar
    ++ [
      "fwupd"
      "tlp"
    ];
  };
}