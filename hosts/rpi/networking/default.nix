{ ... }:
{
  imports = [
    ./nmprofiles.nix
    ../../../modules/dns.nix
    ../../../modules/chrony.nix
  ];
  networking = {
    hostName = "rpi";
    networkmanager = {
      enable = true;
      logLevel = "INFO";
    };
  };
}
