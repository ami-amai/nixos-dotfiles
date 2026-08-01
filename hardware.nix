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
        kernelParams = [ 
            # "amd_pstate=active" 
        ];

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
            device = "/dev/";
            fsType = "btrfs";
        };
        "/home" = {
            device = "/dev/";
            fsType = "btrfs";
            options = [ "subvol=home" ];
        };
        "/nix" = {
            device = "/dev/";
            fsType = "btrfs";
            options = [ "subvol=nix" ];
        };
        "/boot" = {
            device = "/dev/boot";
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