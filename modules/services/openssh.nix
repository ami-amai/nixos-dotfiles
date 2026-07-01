{ pkgs, ... }:

let

  ROOT = /etc/nixos;
  nix_config = import ("${ROOT}/config.nix") { inherit pkgs; };

in

{

  services.openssh = {
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AllowUsers = [ nix_config.user.name ];
    };
  };

  users.users.${nix_config.user.name} = {
    openssh.authorizedKeys.keys = nix_config.user.openssh-keys;
  };

}