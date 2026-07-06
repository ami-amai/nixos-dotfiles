{ pkgs, ... }:

let

  ROOT = ./../..;
  cfg = import (ROOT + "/software.nix") { inherit pkgs; };

in

{
  
  programs.zsh = {
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ssh-identity-git = "sh ~/.config/zsh/scripts/ssh-identity-git.sh";
    };
  };

  home-manager.users.${cfg.user.name} = { config, ... }: {
    xdg.configFile."zsh/scripts/ssh-identity-git.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${ROOT}/.config/zsh/scripts/ssh-identity-git.sh";
      force = true;
    };
  };

}
