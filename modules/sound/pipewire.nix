{ pkgsU, ... }:

{

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  environment.systemPackages = with pkgsU; [
    alsa-utils
    wiremix
  ];

}