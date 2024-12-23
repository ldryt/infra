{ ... }:
{
  imports = [
    ./nmprofiles.nix
    ../../../modules/dnscrypt.nix
    ../../../modules/chrony.nix
  ];
  networking = {
    hostName = "tinkerbell";
    networkmanager = {
      enable = true;
      wifi = {
        powersave = true;
        macAddress = "stable";
      };
      logLevel = "INFO";
    };
  };
}
