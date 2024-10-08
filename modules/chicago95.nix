{ lib
, stdenvNoCC
, fetchFromGitHub
, gtk3
}:

stdenvNoCC.mkDerivation rec {
  pname = "chicago95";
  version = "v3.0.1";

  src = fetchFromGitHub {
    owner = "grassmunk";
    repo = "Chicago95";
    rev = "${version}";
    hash = "sha256-EHcDIct2VeTsjbQWnKB2kwSFNb97dxuydAu+i/VquBA=";
  };

  nativeBuildInputs = [
    gtk3
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/themes
    mv Theme/Chicago95 $out/share/themes

    mkdir -p $out/share/icons
    mv Icons/Chicago95 $out/share/icons
    gtk-update-icon-cache $out/share/icons/Chicago95

    mkdir -p $out/share/sddm/themes
    tar -xzf KDE/SDDM/Chicago95.tar.gz -C "$out/share/sddm/themes/"

    mkdir -p $out/share/fonts
    cp Fonts/vga_font/* $out/share/fonts

    runHook postInstall
  '';

  meta = with lib; {
    description = "Windows 95 theme for linux";
    homepage = "https://github.com/grassmunk/Chicago95";
    license = with licenses; [ gpl3Plus mit ];
    platforms = platforms.linux;
    maintainers = with maintainers; [ GabrielMaguire ];
  };
}
