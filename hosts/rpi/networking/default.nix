{ ... }:
{
  imports = [
    ./nmprofiles.nix
    ../../../modules/dnscrypt.nix
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
