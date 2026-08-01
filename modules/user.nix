{}:

let

  cfg = import ( ../cfg.nix ) { inherit pkgs; };

in

{

  users.users.${cfg.user.name} = {
    isNormalUser = true;
    shell = cfg.user.shell;
    description = "normal user";
    extraGroups = cfg.user.extraGroups;
    packages = with pkgs; []
    ++ cfg.user.packages;
  };

}