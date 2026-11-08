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

  config = lib.mkMerge [
    # -----------------------------------------------------
    # Misc.
    {
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
              system = final.stdenv.hostPlatform.system;
              config.allowUnfree = true;
            };
            signalPkgs = import inputs.nixpkgs-signal {
              system = final.stdenv.hostPlatform.system;
            };
            # zigPkgs = import inputs.nixpkgs-zig {
            #   system = final.stdenv.hostPlatform.system;
            # };
            agentsPkgs = import inputs.nixpkgs-agents {
              system = final.stdenv.hostPlatform.system;
              config.allowUnfree = true;
            };
          })
        ];

        config = {
          allowUnfree = true;
        };
      };

      boot.kernelPackages = pkgs.linuxPackages_6_12;

      # Use the systemd-boot EFI boot loader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # swapDevices = [
      #   {
      #     device = "/var/lib/swapfile";
      #     size = 4 * 1024; # 4 GiB
      #   }
      # ];

      # services.earlyoom = {
      #   enable = true;
      #   freeSwapThreshold = 2;
      #   freeMemThreshold = 2;
      #   extraArgs = [
      #     "-g"
      #     "--avoid '^(Hyprland|kitty|tmux)$'"
      #     "--prefer '^(electron|libreoffice|gimp)$'"
      #   ];
      # };

      networking.networkmanager.enable = true;

      time.timeZone = "America/Los_Angeles";

      services.logind.settings.Login.HandleLidSwitch = "ignore";

      users.users = {
        gabriel = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "dialout"
          ];
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

    # -----------------------------------------------------
    # Misc. desktop environment
    {
      # Enable touchpad support
      services.libinput = {
        enable = true;
        touchpad.naturalScrolling = true;
      };

      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      # programs.waybar = {
      #   enable = true;
      #   package = pkgs.waybar.overrideAttrs (oldAttrs: {
      #     mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      #   });
      # };

      programs.dconf.enable = true;
      services.dbus.enable = true;
      security.polkit.enable = true;

      fonts.packages = with pkgs; [
        nerd-fonts.commit-mono
        nerd-fonts.hack
        nerd-fonts.blex-mono
        nerd-fonts.sauce-code-pro
        ibm-plex
      ];

      systemd.user.services.dunst = {
        enable = true;
        serviceConfig = {
          ExecStart = "${pkgs.dunst}/bin/dunst";
        };
        wantedBy = [ "multi-user.target" ];
      };

      qt.enable = true;

      environment =
        let
          quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
            withX11 = false;
          };
        in
        {
          sessionVariables = {
            WLR_NO_HARDWARE_CURSORS = "1";
            NIXOS_OZONE_WL = "1";
            QML_IMPORT_PATH = "${pkgs.kdePackages.qtdeclarative}/lib/qt-6/qml/:${quickshell}/lib/qt-6/qml/";
          };

          systemPackages = with pkgs; [
            # GUI libraries
            adwaita-icon-theme
            gtk3
            # libsForQt5.polkit-kde-agent
            libsForQt5.qt5.qtwayland

            # LibreOffice
            hunspell
            hunspellDicts.en_US
            libreoffice-qt

            # System benchmark
            glmark2
            sysbench

            # Wayland libraries
            wayland-protocols
            wayland-utils
            wl-clipboard
            wlr-randr
            wlroots
            xwayland

            # Window manager & desktop environment
            awww
            brightnessctl
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
            udisks
            waybar
            wofi
            yazi

            # User programs
            # unstable.openshot-qt # Not working
            bitwarden-cli
            eog
            feh
            firefox
            gimp
            google-chrome
            inkscape
            signalPkgs.signal-desktop
            inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
            kdePackages.kdenlive
            mpv
            nautilus
            obs-studio
            prismlauncher # minecraft launcher
            spotify
            tor
            transmission_4
            transmission_4-qt
            unstable.chromium
            vlc

            # Misc. system
            polkit
          ];
        };
    }

    # -----------------------------------------------------
    # XDG
    {
      xdg = {
        portal = {
          enable = true;
          wlr.enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-hyprland
          ];
        };

        icons.enable = true;

        mime = {
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
      };

      environment.systemPackages = with pkgs; [
        xdg-desktop-portal-gtk # TODO: Do I need this if I also have xdg.portal.extraPortals
        xdg-desktop-portal-hyprland # TODO: ^
      ];
    }

    # -----------------------------------------------------
    # NVIDIA graphics
    {
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
      };

      boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

      environment.systemPackages = with pkgs; [
        nvidia-vaapi-driver
        nvtopPackages.nvidia
      ];
    }

    # -----------------------------------------------------
    # Audio & Bluetooth
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      services.blueman.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = false;
      };

      environment.systemPackages = with pkgs; [
        blueman
        pipewire
        wireplumber
        overskride
      ];
    }

    # -----------------------------------------------------
    # Development environment
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
      };

      environment.systemPackages = with pkgs; [
        # Development environment
        asm-lsp
        ffmpeg
        git
        gnumake
        htop-vim
        jdk
        jujutsu
        kdePackages.qtdeclarative
        kitty
        marksman
        meson
        neovim
        openssl
        openvpn
        perf
        pkg-config
        postman
        qemu
        qmk
        starship
        tmux
        unstable.ghostty
        valgrind
        vim

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
        nixfmt
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

        # CLI utilities
        bc
        conntrack-tools
        ethtool
        eza
        fd
        file
        gifsicle
        inetutils
        jq
        lshw
        poppler
        ripgrep
        stow
        tcpdump
        tree
        unstable.fzf
        unzip
        usbutils
        wget
        zip

      ];
    }

    # -----------------------------------------------------
    # Coding Agents
    {
      environment.systemPackages = with pkgs; [
        agentsPkgs.claude-code
        agentsPkgs.codex
        agentsPkgs.bubblewrap # codex dependency
      ];
    }

    # -----------------------------------------------------
    # Emacs
    {
      # For some reason, I need to completely reboot emacs for config updates
      # to take effect if I use the emacs service.
      # services.emacs.enable = true; # <- Don't do this.

      documentation = {
        enable = true;
        dev.enable = true; # Installs man pages for libraries
        # man.generateCaches = true; # Generates caches so tools like apropos work
      };

      environment.systemPackages = with pkgs; [
        man-pages
        man-pages-posix
        liburing
        emacs
        # emacsPackages.ghostel
      ];
    }

    # -----------------------------------------------------
    # Docker
    {
      nixpkgs.overlays = [ (final: prev: { docker = prev.docker_29; }) ];

      virtualisation.docker = {
        enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };

      environment.systemPackages = with pkgs; [
        dive
        docker
      ];

      users.users.gabriel.extraGroups = [ "docker" ];
    }

    # -----------------------------------------------------
    # Mullvad VPN
    {
      services.mullvad-vpn = {
        enable = true;
        package = pkgs.mullvad-vpn;
      };

      environment.systemPackages = with pkgs; [
        mullvad-vpn
      ];
    }

    # -----------------------------------------------------
    # Security Key / SSH
    (
      let
        yubikeys = {
          # u2f: pamu2fcfg --nouser --origin=pam://gabriel
          home = {
            serial = "37207136";
            u2f = "djjdbhnIPeOwiDUM1pLwqSk/0RujhyUgA04A5Hy9LFUnkbKbgPZUpUxL8n4J3hNHx3cVEap/sEhzseSYzKwPWA==,dOBOjJhVKOlZ9Wad4hdYXHPCGEFpSubbFk97SHsKF2AcGBodFqfTZILhuCkT3rjAfqbIgcGgzxlBrh+Kz3dY6Q==,es256,+presence";
            handle = "id_ed25519_sk";
            sshPublicKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOEXF1SgNGhLEgJNbcdSHPhGgEY0urIoonIaXeR00PWxAAAABHNzaDo= gabrielmaguire";
          };
          travel = {
            serial = "37206904";
            u2f = "PXFmwzsD6UI3Kz2t1pzyGmmiR0aokfS6VMQdA2HpNI7BG5OJwCJYirssgymGVvSMlp8hIlxv9MCmGo6D+SIViA==,iLYtrVHUk7pPToW8BqHUUcYHjXSi2/svoJZDqxdXLNu+7GMir+80eyt38JNW5f+nTf/AkID/AuSJcZA1uGJV+Q==,es256,+presence";
            handle = "id_ed25519_sk_travel";
            sshPublicKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDyLZSBeG/bl4c1GX0OJKBqpzOfmUB8sgTZKTCw4CgsvAAAABHNzaDo= gabrielmaguire@travel";
          };
        };
        keys = lib.attrValues yubikeys;
      in
      {
        environment.systemPackages = with pkgs; [
          yubikey-manager
          pam_u2f
        ];

        services.pcscd.enable = true;

        security.pam.u2f = {
          enable = true;
          control = "sufficient"; # touch OR password
          settings = {
            cue = true;
            origin = "pam://gabriel";
            appid = "pam://gabriel";
            authfile = pkgs.writeText "u2f_keys" "gabriel:${lib.concatStringsSep ":" (map (k: k.u2f) keys)}\n";
          };
        };

        security.pam.services = {
          sudo.u2fAuth = true;
          login = {
            u2fAuth = true;
            # Upgrade login to require touch AND password
            rules.auth.u2f.control = lib.mkForce "required";
          };
        };

        programs.ssh = {
          startAgent = true;
          extraConfig = ''
            ${lib.concatMapStrings (k: ''
              Match exec "ykman list --serials | grep -qx ${k.serial}"
                IdentityFile ~/.ssh/${k.handle}
            '') keys}

            AddKeysToAgent yes

            Host *
              IdentityAgent none
              IdentitiesOnly yes
              ControlMaster auto
              ControlPath ~/.ssh/cm-%C
              ControlPersist 10m

            Host desktop laptop
              User gabriel
          '';
        };

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            AllowUsers = [ "gabriel" ];
          };
        };

        users.users.gabriel.openssh = {
          authorizedKeys.keys = map (k: k.sshPublicKey) keys;
        };
      }
    )

    # -----------------------------------------------------
    # Tailscale
    {
      services.tailscale.enable = true;

      # SSH reachable only over the tailnet
      services.openssh.openFirewall = false;
      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 22 ];
    }

    # -----------------------------------------------------
    # Trezor
    {
      services.trezord.enable = true;
      environment.systemPackages = with pkgs; [
        trezor-suite
      ];
    }

    # -----------------------------------------------------
    # Android
    {
      users.users.gabriel.extraGroups = [ "adbusers" ];
      environment.systemPackages = with pkgs; [
        android-tools
      ];
    }

    # -----------------------------------------------------
    # Zig
    {
      environment.systemPackages =
        let
          zigPkgs = inputs.nixpkgs-zig.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          inherit (zigPkgs) zig zig-shell-completions zls;
        in
        [
          zig
          zig-shell-completions
          zls
        ];
    }
  ];
}
