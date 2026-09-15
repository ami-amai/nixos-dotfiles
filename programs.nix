{ pkgsU, ... }:

{
  programs = {

    # Throne
    throne = {
      enable = true;
      package = pkgsU.throne;
      tunMode.enable = true;
    };

    # Git
    git = {
      enable = true;
      config.user = {
        name = "ami-amai";
        email = "96684291+ami-amai@users.noreply.github.com";
      };
    };

    # Hyprland
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    ## Zsh
    zsh = {
      enable = true;

      ### Zsh Configuration
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      ### Aliases
      shellAliases = {
        ssh-identity-git = "sh ~/.local/share/zsh/scripts/ssh-identity-git.sh";
        #ryzenadj-mode = "~/.config/zsh/scripts/ryzenadj-mode.sh";
      };
    };
  };
}