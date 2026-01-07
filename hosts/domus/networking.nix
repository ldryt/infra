{ ... }:
{
  networking = {
    hostName = "domus";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
    enableIPv6 = false;
    useNetworkd = true;
  };
}
