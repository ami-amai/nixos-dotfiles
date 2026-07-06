{ pkgs, ... }:

let

  ROOT = ./../..;
  cfg = import (ROOT + "/software.nix") { inherit pkgs; };

in

{

  home-manager.users.${cfg.user.name} = { config, ... }: {
    xdg.configFile."hypr/" = {
      source = config.lib.file.mkOutOfStoreSymlink "${ROOT}/.config/hypr/";
      force = true;
    };
  };

}