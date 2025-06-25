{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "desktop";

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "Chicago95";
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "gabriel" ];
    };
  };

  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "192.168.0.0/24"
      "192.168.1.0/24"
      "10.8.0.0/24"
    ];
  };

  services.openvpn.servers = {
    chatprosim = {
      config = ''
        dev tun0
        proto udp
        port 1194
        tun-mtu 1300

        ifconfig 10.8.0.1 10.8.0.2
        push "route 10.8.0.1 255.255.255.255"

        # Alternative for multiple clients:
        # server 10.8.0.0 255.255.255.0
        # push "route 10.8.0.0 255.255.255.0"

        secret /root/openvpn-chatprosim-static.key

        cipher AES-256-CBC
        auth-nocache

        comp-lzo
        keepalive 10 60
        ping-timer-rem
        persist-tun
        persist-key
      '';
      autoStart = false;
      updateResolvConf = true;
    };
  };

  networking.nat = {
    enable = true;
    externalInterface = "enp9s0";
    internalInterfaces = [ "tun0" ];
  };

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 1194 ];
    allowedTCPPorts = [
      22
      8080 # chatprosim development server port
    ];
    allowPing = true;
  };
}
