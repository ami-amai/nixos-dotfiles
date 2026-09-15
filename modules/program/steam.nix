{ pkgsU, ... }:

{

  programs = {
    steam.enable = true;
    gamescope.enable = true;
    gamemode.enable = true;
  };

  environment.systemPackages = with pkgsU; [
    protonup-qt protontricks
  ];

}