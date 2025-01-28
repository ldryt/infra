{ pkgs, ... }:
{
  imports = [
    ./nmprofiles.nix
    ../../../modules/dns.nix
    ../../../modules/chrony.nix
  ];
  environment.systemPackages = [ pkgs.iwd ]; # for iwctl
  networking = {
    hostName = "tinkerbell";
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = true;
        macAddress = "stable-ssid";
      };
      logLevel = "INFO";
    };
  };
}
