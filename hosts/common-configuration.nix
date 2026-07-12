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
      (final: prev: {
        docker = prev.docker_29;
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

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4 * 1024; # 4 GiB
    }
  ];

  services.earlyoom = {
    enable = true;
    freeSwapThreshold = 2;
    freeMemThreshold = 2;
    extraArgs = [
      "-g"
      "--avoid '^(Hyprland|kitty|tmux)$'"
      "--prefer '^(electron|libreoffice|gimp)$'"
    ];
  };

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  time.timeZone = "America/Los_Angeles";

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
      "application/pdf" = "firefox.desktop";
      "image/*" = [
        "eog"
        "gimp.desktop"
      ];
      "text/*" = "nvim";
      "video/*" = "mpv";
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.commit-mono
    nerd-fonts.hack
    nerd-fonts.blex-mono
    nerd-fonts.sauce-code-pro
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

  qt.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  services.trezord.enable = true;

  # programs.adb.enable = true;

  environment =
    let
      quickshell = inputs.quickshell.packages.${pkgs.system}.default.override {
        withX11 = false;
      };
    in
    {
      sessionVariables = {
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";
        QML_IMPORT_PATH = "${pkgs.kdePackages.qtdeclarative}/lib/qt-6/qml/:${quickshell}/lib/qt-6/qml/";
      };

      systemPackages =
        let
          zigPkgs = inputs.nixpkgs-zig.legacyPackages.${pkgs.system};
          inherit (zigPkgs) zig zig-shell-completions zls;
          signal-desktop = inputs.nixpkgs-signal.legacyPackages.${pkgs.system}.signal-desktop;
        in
        with pkgs;
        [
          # Terminal emulators
          kitty
          unstable.ghostty

          # GUI libraries
          adwaita-icon-theme
          gtk3
          # libsForQt5.polkit-kde-agent
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
          config.boot.kernelPackages.perf
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
          qemu
          qmk
          valgrind

          # Bash
          bash-language-server
          shellcheck
          shfmt

          # C/C++
          bear
          clang_21
          cmake
          gcc
          gdb
          libcxx
          lldb
          llvmPackages_21.clang-tools
          neocmakelsp

          # Rust
          cargo
          rustc

          # Lua
          lua
          lua-language-server
          luajit
          stylua

          # Python
          isort
          pyright
          python3.pkgs.black
          python3
          unstable.uv

          # Nix
          nixfmt-rfc-style
          nil
          nixd

          # Go
          delve
          go
          gopls

          # HTML/CSS/JS
          emmet-ls
          eslint
          prettier
          nodejs
          tailwindcss
          tailwindcss-language-server
          typescript-language-server
          vscode-langservers-extracted

          # Zig
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
          gifsicle
          jq
          lshw
          poppler
          ripgrep
          tcpdump
          tree
          unstable.fzf
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
          swappy
          swww
          waybar
          wofi
          yazi

          # User programs
          bitwarden-cli
          eog
          feh
          firefox
          gimp
          google-chrome
          htop-vim
          inkscape
          inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
          kdePackages.kdenlive
          mpv
          mullvad-vpn
          nautilus
          neovim
          nvtopPackages.nvidia
          obs-studio
          signal-desktop
          spotify
          starship
          tmux
          tor
          transmission_4
          transmission_4-qt
          trezor-suite
          unstable.chromium
          unstable.openshot-qt # Not working
          vim
          vlc

          # Games
          prismlauncher # minecraft launcher

          # Misc. system
          polkit
        ];
    };

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
