# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
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
        # Opinionated: disable global registry
        flake-registry = "";
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
      };
      # Opinionated: disable channels
      channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

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
        "Hack"
        "CommitMono"
        "SourceCodePro"
      ];
    })
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
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
      bear
      cargo
      clang
      clang-tools
      cmake
      dive
      docker
      emmet-ls
      gcc
      gdb
      git
      gnumake
      go
      gopls
      isort
      jdk
      kdePackages.qtdeclarative
      libcxx
      lldb
      lua
      lua-language-server
      luajit
      marksman
      meson
      nautilus
      neocmakelsp
      nixfmt-rfc-style
      nodePackages.eslint
      nodePackages.prettier
      nodejs
      openssl
      openvpn
      pkg-config
      postman
      pyright
      python311Packages.black
      python3Full
      rustc
      shfmt
      stylua
      tailwindcss
      tailwindcss-language-server
      typescript-language-server
      valgrind
      vscode-langservers-extracted
      zig
      zig-shell-completions
      zls

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

      # Window manager & desktop environment
      chicago95
      dunst
      extra-icons
      grim
      hyprland
      hyprland-autoname-workspaces
      kanshi
      libnotify
      quickshell
      slurp
      swww
      waybar
      wofi

      # User programs
      bitwarden-cli
      feh
      firefox
      gimp
      google-chrome
      htop-vim
      inkscape
      kdePackages.kdenlive
      mpv
      mullvad-vpn
      neofetch
      neovim
      nvtopPackages.nvidia
      obs-studio
      spotify
      starship
      tmux
      tor
      transmission_4
      transmission_4-qt
      trezor-suite
      vim
      vlc
      yazi
      unstable.chromium
      unstable.openshot-qt # Not working
      inputs.nixpkgs-signal.legacyPackages.${system}.signal-desktop

      # Games
      prismlauncher # minecraft launcher

      # Misc. system
      polkit
    ];

  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    gabriel = {
      # TODO: You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      # initialPassword = "correcthorsebatterystaple";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
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

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = "no";
      # Opinionated: use keys only.
      # Remove if you want to SSH using passwords
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
