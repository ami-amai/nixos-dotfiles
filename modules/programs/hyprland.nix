{ pkgs, ... }:

{

    home-manager.users.${nix_config.user.name} = { config, ... }: {
    xdg.configFile."hypr/" = {
      source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/.config/hypr/";
      force = true;
    };
  };

}