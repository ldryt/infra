{ ... }:
{
  networking = {
    hostName = "silvermist";
    useNetworkd = true;
    enableIPv6 = false;
    usePredictableInterfaceNames = false; # just one eth0
  };

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    networkConfig.DHCP = "ipv4";
  };
}
