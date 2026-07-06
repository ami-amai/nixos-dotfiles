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
  };

  boot = cfg.boot;
  fileSystems = cfg.fileSystems;
  zramSwap = cfg.zramSwap;
  
}