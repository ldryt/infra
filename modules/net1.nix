{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gns3-gui
    gns3-server
    inetutils
    dynamips
    tigervnc
    vpcs
    alacritty
    ethtool
    libpcap
    wireshark
  ];

  virtualisation.docker.enable = true;
  virtualisation.virtualbox.host.enable = true;

  security.wrappers.ubridge = {
    source = "${pkgs.ubridge}/bin/ubridge";
    capabilities = "cap_net_admin,cap_net_raw=ep";
    owner = "root";
    group = "root";
    permissions = "u+rx,g+x,o+x";
  };
}
