{ lib
, stdenv
, fetchurl
, coreutils
, procps
, zsh
, which
, iputils
, autoPatchelfHook
, dpkg
, glibc
, alsa-lib
, gtk3
, nss
, mesa
, nspr
}:

stdenv.mkDerivation rec {
  pname = "surfshark";
  version = "3.0.3";

  src = fetchurl {
    # url = "https://ocean.surfshark.com/debian/pool/main/s/surfshark/surfshark_${version}_amd64.deb";
    url = "https://ocean.surfshark.com/debian/pool/main/s/surfshark_${version}_amd64.deb";
    sha256 = "sha256-U0pG0JlPKMygFV78Yl2UnYECIdPSRGgdxrj0tGse+vg=";
  };

# This bit is the systemd script, but it doesn't work here and needs its own service nix
#  systemd.services.surfsharkd2 = {
#    enable = true;
#    descriptions = "Surfshark Daemon2";
#    serviceConfig = {
#    ExecStart = "/opt/Surfshark/resources/dist/resources/surfsharkd2.js";
#    Restart="on-failure";
#    RestartSec=5;
#    IPAddressDeny="any";
#    RestrictRealtime=true;
#    ProtectKernelTunables=true;
#    ProtectSystem="full";
#    RestrictSUIDSGID=true;
#    };
#    wantedBy = [ "default.target" ];
#  };

  # dontConfigure = true;
  # dontBuild = true;
  #
  # nativeBuildInputs = [ autoPatchelfHook dpkg ];

  installPhase = ''
    # mkdir $out
    # dpkg-deb -R $src $out

    # Extract package data
    tar -xJ -f $src -C $out
    install -D -m644 $out/opt/Surfshark/resources/dist/resources/surfsharkd.js.LICENSE.txt $out/usr/share/licenses/surfshark-client/LICENSE
  '';

  buildInputs = [ glibc alsa-lib gtk3 nss mesa nspr coreutils ];

  # meta = with lib; {
  #   description = "Surfshar VPN CLI";
  #   homepage = "https://surfshark.com";
  #   license = licenses.unfree;
  #   maintainers = [ "binh" ];
  #   platforms = [ "x86_64-linux" ];
  # };
}
