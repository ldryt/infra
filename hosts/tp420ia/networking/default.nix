{ ... }:
{
  imports = [ ./nmprofiles.nix ];
  networking = {
    hostName = "tp420ia";
    networkmanager.enable = true;
    enableIPv6 = false;
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
  };
}
