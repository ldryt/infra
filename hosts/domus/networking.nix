{ ... }:
{
  networking = {
    hostName = "domus";
    nameservers = [
      "86.54.11.100"
      "86.54.11.200"
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
