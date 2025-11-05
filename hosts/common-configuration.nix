{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.gabriel = import ./home.nix;
  };

  nixpkgs = {
    overlays = [
      (final: prev: import ../pkgs final)
      (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
        };
      })
    ];

    config = {
      allowUnfree = true;
    };
  };

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";

        # Disable global registry
        flake-registry = "";

        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
      };
      # Disable channels
      channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  time.timeZone = "America/Detroit";

  services.logind.lidSwitch = "ignore";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
  };

  programs.dconf.enable = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  services.dbus.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  services.blueman.enable = true;

  security.polkit.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  xdg.icons.enable = true;

  xdg.mime = {
    enable = true;
    defaultApplications = {
      "image/*" = [
        "feh"
        "gimp.desktop"
      ];
    };
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "CommitMono"
        "Hack"
        "IBMPlexMono"
        "SourceCodePro"
      ];
    })
    ibm-plex
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support
  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  systemd.user.services.dunst = {
    enable = true;
    serviceConfig = {
      ExecStart = "${pkgs.dunst}/bin/dunst";
    };
    wantedBy = [ "multi-user.target" ];
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  services.trezord.enable = true;

  programs.adb.enable = true;

  environment.systemPackages =
    let
      quickshell = inputs.quickshell.packages.${pkgs.system}.default.override {
        withX11 = false;
      };

      nixos25_05 = inputs.nixpkgs-25-05.legacyPackages.${pkgs.system};
      zigPkgs = inputs.nixpkgs-zig.legacyPackages.${pkgs.system};
      signalPkgs = inputs.nixpkgs-signal.legacyPackages.${pkgs.system};
    in
    with pkgs;
    [
      # Terminal emulators
      kitty
      unstable.ghostty

      # GUI libraries
      adwaita-icon-theme
      gtk3
      libsForQt5.polkit-kde-agent
      libsForQt5.qt5.qtwayland

      # LibreOffice
      hunspell
      hunspellDicts.en_US
      libreoffice-qt

      # Audio & video & bluetooth
      blueman
      brightnessctl
      ffmpeg
      pipewire
      wireplumber

      # NVIDIA
      nvidia-vaapi-driver

      # Development environment
      android-tools
      asm-lsp
      cargo
      dive
      docker
      git
      gnumake
      jdk
      kdePackages.qtdeclarative
      marksman
      meson
      openssl
      openvpn
      pkg-config
      postman
      rustc
      valgrind
      config.boot.kernelPackages.perf
      qemu
      nixos25_05.qmk

      # Bash
      shfmt
      shellcheck
      bash-language-server

      # C/C++
      bear
      nixos25_05.clang_21
      nixos25_05.llvmPackages_21.clang-tools
      cmake
      neocmakelsp
      gcc
      gdb
      libcxx
      lldb

      # Go
      go
      gopls

      # Lua
      lua
      lua-language-server
      luajit
      stylua

      # Nix
      nil
      nixd
      nixfmt-rfc-style

      # Python
      isort
      pyright
      python3Full
      python311Packages.black
      unstable.uv

      # HTML/CSS/JS
      emmet-ls
      nodePackages.eslint
      nodePackages.prettier
      nodejs
      tailwindcss
      tailwindcss-language-server
      typescript-language-server
      vscode-langservers-extracted

      # Zig
      zigPkgs.zig
      zigPkgs.zig-shell-completions
      zigPkgs.zls

      # System benchmark
      glmark2
      sysbench

      # Wayland libraries
      wayland-protocols
      wayland-utils
      wl-clipboard
      wlr-randr
      wlroots
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
      xwayland

      # CLI utilities
      bc
      conntrack-tools
      ethtool
      eza
      fd
      file
      fzf
      gifsicle
      jq
      lshw
      poppler
      ripgrep
      tcpdump
      tree
      unzip
      usbutils
      wget
      zip

      # Window manager & desktop environment & user programs
      bitwarden-cli
      chicago95
      dunst
      extra-icons
      feh
      firefox
      gimp
      google-chrome
      grim
      htop-vim
      hyprland
      hyprland-autoname-workspaces
      inkscape
      nixos25_05.yazi
      signalPkgs.signal-desktop
      kanshi
      kdePackages.kdenlive
      libnotify
      mpv
      mullvad-vpn
      nautilus
      neofetch
      neovim
      nvtopPackages.nvidia
      obs-studio
      polkit
      prusa-slicer
      quickshell
      slurp
      spotify
      starship
      swappy
      swww
      tmux
      tor
      transmission_4
      transmission_4-qt
      trezor-suite
      unstable.chromium
      unstable.openshot-qt # Not working
      vim
      vlc
      waybar
      wofi

      # Games
      prismlauncher # minecraft launcher
    ];

  users.users = {
    gabriel = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      extraGroups = [
        "wheel"
        "docker"
        "dialout"
        "adbusers"
      ];
    };
  };

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  programs.ssh = {
    startAgent = true;
    extraConfig = "AddKeysToAgent yes";
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # nix.gc = {
  #   automatic = true;
  #   dates = "weekly";
  #   options = "--delete-older-than 30d";
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
