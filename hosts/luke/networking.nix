{ ... }:
{
  networking = {
    hostName = "luke";
    enableIPv6 = false;
    useNetworkd = true;
    useDHCP = true;
  };
}
