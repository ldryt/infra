{ pkgs, ... }:
let
  apIF = "ap0";
  stationIF = "wlan0";
in
{
  imports = [ ../../modules/mdns-publish.nix ];

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  systemd.network.links = {
    "10-${apIF}" = {
      matchConfig.PermanentMACAddress = "b8:27:eb:db:1e:3b";
      linkConfig.Name = apIF;
    };
    "10-${stationIF}" = {
      matchConfig.PermanentMACAddress = "28:87:ba:a4:c3:cd";
      linkConfig.Name = stationIF;
    };
  };

  networking = {
    hostName = "domus";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
    dhcpcd.enable = false;
    wireless.iwd = {
      enable = true;
      # https://man.archlinux.org/man/iwd.config.5
      settings = {
        General = {
          EnableNetworkConfiguration = true;
          AddressRandomization = "network";
          Country = "FR";
        };
        Network = {
          EnableIPv6 = false;
        };
      };
    };
    nat = {
      enable = true;
      externalInterface = stationIF;
      internalInterfaces = [ apIF ];
    };
    firewall.allowedUDPPorts = [ 67 ]; # DHCP
  };
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  systemd.tmpfiles.rules =
    let
      rosetta = (
        pkgs.writeText "iwd_rosetta.psk" ''
          [Security]
          PreSharedKey=80eb518e636de9d2d275f79083aed5399a0cadf520e1a1cb49a384bac878ad7c
        ''
      );
    in
    [
      "C /var/lib/iwd/rosetta.psk 0600 root root - ${rosetta}"
    ];

  systemd.services."iwd-start-ap" =
    let
      domusAPconf = (
        pkgs.writeText "iwd_domus.ap" ''
          [General]
          DisableHT=true

          [Security]
          Passphrase=escalier

          [IPv4]
          Address=10.10.10.10
          Gateway=10.10.10.10
          Netmask=255.255.255.0
          DNSList=9.9.9.9,149.112.112.112
        ''
      );
    in
    {
      description = "iwd AP on ${apIF}";
      requires = [ "sys-subsystem-net-devices-${apIF}.device" ];
      after = [
        "iwd.service"
        "sys-subsystem-net-devices-${apIF}.device"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.iwd
        pkgs.iw
        pkgs.busybox
      ];
      script = ''
        set -xeu

        ln -s ${domusAPconf} /var/lib/iwd/ap/domus.ap

        if ! iw dev ${apIF} info | grep -q "type AP"
        then
          iwctl device ${apIF} set-property Mode ap
        fi

        if ! iw dev ${apIF} info | grep -q "ssid"
        then
          iwctl ap ${apIF} start-profile domus
        fi
      '';
    };
}
