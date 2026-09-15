{ pkgs, pkgsU, lib, ... }:

{

  HOSTNAME = "nixos";

  NIXOS = {
    stateVersion = "26.05";
    allowUnfree = true;
    experimentalFeatures = [
      "nix-command"
      "flakes"
    ];
  };

  FILESYSTEM = {
      # Root Partition
    "/" = {
        device = "/dev/nvme0n1p3";
        fsType = "btrfs";
    };
    # Home subvolune
    "/home" = {
        device = "/dev/nvme0n1p3";
        fsType = "btrfs";
        options = [ "subvol=home" ];
    };
    # Nix subvolume
    "/nix" = {
        device = "/dev/nvme0n1p3";
        fsType = "btrfs";
        options = [ "subvol=nix" ];
    };
    # Boot Partition
    "/boot" = {
        device = "/dev/nvme0n1p4";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  HARDWARE = {
    bluetooth.enable = true;
    enableRedistributableFirmware = true;
    cpu = {
      amd = {
        updateMicrocode = lib.mkDefault true;
        ryzen-smu.enable = true;
      };
    };
  };

  BOOT = {
    # Init Modules
    initrd = {
        availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
        kernelModules = [ ];
    };
    # Loader
    loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
  };

  KERNEL = {
    packages = pkgs.linuxPackages_latest;
    modules = [
      "kvm-amd"
    ];
    extraModules = [];
    params = [];
  };

  ZRAMSWAP = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
  };

  ENVIRONMENT = {
    networkManager = true;
    displayManager = "ly";
    timeZone = "Europe/Moscow";
    layout = {
      default = "us";
      extra = "ru";
    };
    locale = {
      default = "en_US";
      extra = "ru_RU";
    };
    packages = with pkgsU; [
          # TUIs
          bluetuith
          htop btop
          nano mc
          # Utils
          curl wget
          git
          zip unzip
          usbutils
          python3 python3Packages.pip
          # FS
          ntfs3g # mtpfs 
    ];
  };

  USER = {
    name = "ami";
    shell = pkgsU.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    #polkitAgent = true;
  };

  HOME = {
    symlinks = {
        ".config/hypr".source = "../.config/hypr";
        ".config/zsh".source = "../.config/zsh";
    };
    packages = with pkgsU; [
        # Hyprland
        hyprshot hyprpolkitagent awww kitty
        rofi
        # Web
        telegram-desktop discord
        firefox chromium
        spotify
        # Media
        mpv ffmpeg
        # Draw
        krita xppen_4
        # Coding
        vscode direnv nodejs
        unityhub
        # Games
        lutris
        # Android
        android-tools scrcpy
    ];
  };
}
