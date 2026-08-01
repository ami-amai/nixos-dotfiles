{ pkgs, ... }:

let

  ROOT = ./../..;
  cfg = import (ROOT + "/software.nix") { inherit pkgs; };

in

{

  # Hyprpolkit Agent
  ## Package
  environment.systemPackages = with pkgs; [
    hyprpolkitagent
  ];

  ## Systemd Service
  systemd.user.services.hyprpolkitagent = {
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";

    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      TimeoutStopSec = "5sec";
    };
  };

  # Configuration
  home-manager.users.${cfg.user.name} = { config, ... }: {
    xdg.configFile."hypr/" = {
      source = config.lib.file.mkOutOfStoreSymlink "${ROOT}/.config/hypr/";
      force = true;
    };
  };

}