# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {

# let
#   # chicago95 = with pkgs; import ../modules/chicago95/default.nix { inherit lib stdenvNoCC fetchFromGitHub gtk3; };
#   chicago95 = pkgs.callPackage ../modules/chicago95 {};
# in {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example
    # ../modules/surfshark.nix

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  # nixpkgs = {
  #   # You can add overlays here
  #   overlays = [
  #     # Add overlays your own flake exports (from overlays and pkgs dir):
  #     # outputs.overlays.additions
  #     # outputs.overlays.modifications
  #     # outputs.overlays.unstable-packages
  #
  #     # You can also add overlays exported from other flakes:
  #     # neovim-nightly-overlay.overlays.default
  #
  #     # Or define it inline, for example:
  #     # (final: prev: {
  #     #   hi = final.hello.overrideAttrs (oldAttrs: {
  #     #     patches = [ ./change-hello-to-hi.patch ];
  #     #   });
  #     # })
  #   ];
  #   # Configure your nixpkgs instance
  #   config = {
  #     allowUnfree = true;
  #   };
  # };

  # TODO: Set your username
  home = {
    username = "gabriel";
    homeDirectory = "/home/gabriel";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
    style.package = pkgs.adwaita-qt;
  };

  gtk = {
    enable = true;

    # cursorTheme.package = pkgs.bibata-cursors;
    # cursorTheme.name = "Bibata-Modern-Ice";

    theme.package = pkgs.chicago95;
    theme.name = "Chicago95";

    iconTheme.package = pkgs.chicago95;
    iconTheme.name = "Chicago95";
  };

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}