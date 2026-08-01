{ pkgs, config, throne-nixpkgs, ... }:

let

  thronePkgs = import throne-nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
  };

in

{

  # Boot Configuration
  boot = {
    ## Kernel
    kernelPackages = pkgs.linuxPackages_latest;

    ## Kernel Modules
    kernelModules = [ "kvm-amd" ];
        
    ## Kernel Parametrs
    kernelParams = [ 
      # "amd_pstate=active" 
    ];

    ## Init Modules
    initrd = {
        availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
        kernelModules = [ ];
    };

    ## Extra kernel modules
    extraModulePackages = [ ];

    ## Loader
    loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
  };

  # FileSystem Configuration
  fileSystems = {
    ## Root Partition
    "/" = {
        device = "/dev/nvme0n1p3";
        fsType = "btrfs";
    };
    ## Home subvolune
    "/home" = {
        device = "/dev/nvme0n1p3";
        fsType = "btrfs";
        options = [ "subvol=home" ];
    };
    ## Nix subvolume
    "/nix" = {
        device = "/dev/nvme0n1p3";
        fsType = "btrfs";
        options = [ "subvol=nix" ];
    };
    ## Boot Partition
    "/boot" = {
        device = "/dev/nvme0n1p4";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  # ZramSwap Configuration
  zramSwap = {
      enable = true;
      memoryPercent = 50;
      algorithm = "zstd";
  };

  # NixOS Configuration
  nixos = {
    ## Version of Release
    stateVersion = 26.05;

    ## Allow Unfree
    unfreePkgs = true;

    ## Experimental Features
    experimentalFeatures = [
      "nix-command"
      "flakes"
    ];
  };

  # System Configuration
  system = {

    ## HostName
    hostName = "nixos";
    networkManager = true;
    bluetooth = true;

    ## Timeone
    timeZone = "Europe/Moscow";

    ## TTY Layoyt
    layout = {
      default = "us";
      extra = "ru";
    };

    ## TTY Localization
    locale = {
      default = "en_US";
      extra = "ru_RU";
    };

    ## Display Manager
    displayManager = "ly";

    ## Environment Packages
    environmentPackages = with pkgs; []
    ++ [
      mc
      btop
      bluetuith
      wiremix alsa-utils
    ] ### TUIs
    ++ [
      android-tools
      fastfetch
      python3 nodejs
      mtpfs ntfs3g
      ryzenadj
    ]; ## Utils
  };

  # User Configuration
  user = {

    ## Name
    name = "ami";

    ## Shell Package
    shell = pkgs.zsh;

    ## Extra Groups
    extraGroups = [
      "networkmanager"
      "wheel"
    ];

    ## Polkit Agent
    polkitAgent = true;

    ## User Packages
    packages = with pkgs; []
    ++ [
      hyprshot
      awww
      rofi
      kitty
      hyprpolkitagent
    ] ## Hyrpland
    ++ [ 
      telegram-desktop
      discord
      spotify
      blockbench
      chromium
      firefox
      vscode
      krita
      xppen_4
    ] ### Programs
    ++ [
      prismlauncher
    ] ### Games
    ++ [
      mpv
      openblas
    ] ### Utils
    ++ [
      mangohud
      protonup-qt
      protontricks
      vulkan-tools
      mesa-demos
      gamemode
    ] ### Steam Utils
    ++ [
      direnv
    ]; ### VsCode Utils
  };

  # Home-Manager Configuration
  home = {

    ## Home-Manager Symlinks
    files = {

      ### Hyprland Config
      ".config/hypr".source = 
        config.lib.file.mkOutOfStoreSymlink "./.config/hypr";

      ### Zsh
      ".local/share/zsh/".source = 
        config.lib.file.mkOutOfStoreSymlink "./.local/share/zsh";

    };
  };



  # Flakes Configuration
  flake = {};

  # Programs Configuration
  programs = {

    ## Throne
    throne = {
      enable = true;

      ### Throne Package
      package = thronePkgs.throne;

      ### Throne TunMode
      tunMode = {
        enable = true;
      };
    };

    ## Git
    git = {
      enable = true;
      config = {
        user = {
          name = "ami-amai";
          email = "96684291+ami-amai@users.noreply.github.com";
        };
      };
    };

    ## Hyprland
    hyprland = {
      enable = true;

      ### Xwayland support
      xwayland = {
        enable = true;
      };
    };
    
    ## Zsh
    zsh = {
      enable = true;

      ### Zsh Configuration
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      ### Aliases
      shellAliases = {
        ssh-identity-git = "sh ~/.local/share/zsh/scripts/ssh-identity-git.sh";
        ryzenadj-mode = "~/.config/zsh/scripts/ryzenadj-mode.sh";
      };
    };

    ## Steam
    steam = {
      enable = true;
    };

    ## Gamescope
    gamescope = {
      enable = true;
    };

    ## Gamemode
    gamemode = {
      enable = true;
    };

  };

  # Services Configuration

  services = {

    ## Pipewire Sound
    pipwire = {
      enable = true;

      ### Pipewire alsa support
      alsa = {
        enable = true;
        support32Bit = true;
      };

      ### Pipewire pulse support
      pulse = {
        enable = true;
      };
    };


    ## TLP
    tlp = {
      enable = true;

      ### TLP Settings
      settings = {
        #### USB Autosuspend
        USB_AUTOSUSPEND = 0;
      };
    };
  };

  # Security Configuration
  security = {

    ## For Pipewire
    rtkit ={
      enable = true;
    };
  };

}