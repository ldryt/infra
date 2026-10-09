{ ... }:
{
  networking = {
    hostName = "silvermist";
    useNetworkd = true;
    useDHCP = true;
    enableIPv6 = false;
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
  };
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.UseDNS = false;
}
