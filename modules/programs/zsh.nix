{ pkgs, ... }:

let

  ROOT = /etc/nixos;
  nix_config = import ("${ROOT}/config.nix") { inherit pkgs; };

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

  home-manager.users.${nix_config.user.name} = { config, ... }: {
    xdg.configFile."zsh/scripts/ssh-identity-git.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/.config/zsh/scripts/ssh-identity-git.sh";
      force = true;
    };
  };

}
