{ ... }:
{
  networking = {
    hostName = "domus";
    nameservers = [
      "45.90.28.178"
      "45.90.30.178"
    ];
    enableIPv6 = false;
    useNetworkd = true;
  };

  services.resolved.settings.Resolve.FallbackDNS = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  systemd.network.wait-online.extraArgs = [ "--interface=enp2s0f3u2u2:routable" ];
}
