# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  chicago95 = pkgs.callPackage ../modules/chicago95.nix {};
  extra-icons = pkgs.callPackage ./extra-icons {};
}
