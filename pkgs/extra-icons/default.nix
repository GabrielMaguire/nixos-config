{
  lib,
  pkgs,
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "extra-icons";
  version = "0.0.1";

  src = ./.;

  nativeBuildInputs = with pkgs; [
    imagemagick # for resize
    inkscape # for svgs
  ];

  # Add these environment variables to prevent Inkscape from trying to create user config files
  HOME = "$TMPDIR";
  XDG_CONFIG_HOME = "$TMPDIR/.config";
  XDG_CACHE_HOME = "$TMPDIR/.cache";
  XDG_DATA_HOME = "$TMPDIR/.local/share";

  installPhase = ''
    mkdir -p $out/share/icons/hicolor/scalable/apps/
    for icon in ${src}/raster/*; do
      icon_name=$(basename "$icon")
      icon_name_no_ext=''${icon_name%.*}
      inkscape -p "$icon" -o "$out/share/icons/hicolor/scalable/apps/extra-scale-''${icon_name%.*}.svg"
      for i in 16 24 48 64 96 128 256 512; do
        mkdir -p $out/share/icons/hicolor/''${i}x''${i}/apps
        magick "$icon" -background none -density 300 -resize "''${i}x''${i}" "$out/share/icons/hicolor/''${i}x''${i}/apps/extra-''${icon_name_no_ext}.png"
      done
    done
    for icon in ${src}/vector/*; do
      icon_name=$(basename "$icon")
      cp "$icon" "$out/share/icons/hicolor/scalable/apps/extra-scale-$icon_name"
      inkscape -p "$icon" -o "$out/share/icons/hicolor/scalable/apps/extra-''${icon_name%.*}-svg.svg"
    done
  '';
}
