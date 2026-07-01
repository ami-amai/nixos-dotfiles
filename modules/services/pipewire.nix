{ ... }:

{
  security.rtkit.enable = true;

  services.pipewire = {
    alsa.support32Bit = true;
  };
}