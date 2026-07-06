{ pkgs, ... }:

{

    hostName = "nixos";
    networkManager = true;
    bluetooth = true;

    # Bootloader
    boot = {

        # Kernel
        kernelPackages = pkgs.linuxPackages_latest;

        # Kernel Modules
        kernelModules = [ "kvm-amd" ];
        
        # Kernel Parametrs
        kernelParams = [];

        # Init Modules
        initrd = {
            availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
            kernelModules = [ ];
        };

        # Extra kernel modules
        extraModulePackages = [ ];

        # Loader
        loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
        };
    };

    # Partitons
    fileSystems = {
        "/" = {
            device = "/dev/1";
            fsType = "btrfs";
        };
        "/home" = {
            device = "/dev/1";
            fsType = "btrfs";
            options = [ "subvol=home" ];
        };
        "/nix" = {
            device = "/dev/1";
            fsType = "btrfs";
            options = [ "subvol=nix" ];
        };
        "/boot" = {
            device = "/dev/2";
            fsType = "vfat";
            options = [ "fmask=0077" "dmask=0077" ];
        };
    };
    
    # Swap
    zramSwap = {
        enable = true;
        memoryPercent = 50;
        algorithm = "zstd";
    };

}