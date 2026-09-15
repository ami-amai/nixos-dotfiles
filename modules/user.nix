{ cfg, ... }:

{

  # USER
  users.users.${cfg.USER.name} = {
    isNormalUser = true;
    shell = cfg.USER.shell;
    extraGroups = cfg.USER.extraGroups;
    description = "Normal user ${cfg.USER.name}";
  };
  
}