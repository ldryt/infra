{ ... }:
{
  networking = {
    hostName = "domus";
    nameservers = [
      "76.76.2.0"
      "76.76.10.0"
    ];
    enableIPv6 = false;
    useNetworkd = true;
  };

  services.resolved.settings.Resolve.FallbackDNS = "";

  systemd.network = {
    networks."99-ethernet-default-dhcp" = {
      dhcpV4Config.UseDNS = false;
      dhcpV6Config.UseDNS = false;
      ipv6AcceptRAConfig.UseDNS = false;
    };
    wait-online.extraArgs = [ "--interface=enp2s0f3u2u2:routable" ];
  };
}
