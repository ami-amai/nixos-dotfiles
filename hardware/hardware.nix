{ pkgs, modulesPath, lib, config, ... }: 

let

  ROOT = ./..;
  cfg = import (ROOT + "/hardware.nix") { inherit pkgs; };

in

{

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  networking = {
    hostName = cfg.hostName;
    networkmanager.enable = cfg.networkManager;
  };

  hardware = {
    bluetooth.enable = cfg.bluetooth;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # Enable the Ryzen SMU kernel driver so RyzenAdj uses serialized kernel access
    # instead of the conflicting and less secure /dev/mem fallback.
    cpu.amd.ryzen-smu.enable = true;
    enableRedistributableFirmware = true;
  };

  boot = cfg.boot;
  fileSystems = cfg.fileSystems;
  zramSwap = cfg.zramSwap;
  
}
