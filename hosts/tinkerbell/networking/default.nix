{ ... }:
{
  imports = [
    ./nmprofiles.nix
    ../../../modules/dns.nix
    ../../../modules/chrony.nix
  ];
  networking = {
    hostName = "tinkerbell";
    networkmanager = {
      enable = true;
      wifi = {
        powersave = true;
        macAddress = "random";
      };
      logLevel = "INFO";
    };
  };
}
