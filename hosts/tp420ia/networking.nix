{ ... }:
{
  networking = {
    hostName = "tp420ia";
    enableIPv6 = false;
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
    useNetworkd = true;
    useDHCP = false;
  };

  systemd.network =
    let
      name = "ethernet-wan";
      mac = "00:e0:4c:68:00:78";
    in
    {
      links."10-${name}" = {
        matchConfig.PermanentMACAddress = mac;
        linkConfig.Name = name;
      };
      networks."10-ethernet-wan" = {
        matchConfig.Name = name;
        DHCP = "ipv4";
        dhcpV4Config.UseDNS = false;
      };
    };
}
