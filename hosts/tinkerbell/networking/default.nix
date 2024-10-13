{ ... }:
{
  imports = [ ./nmprofiles.nix ];
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
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [ "time.cloudflare.com" ];
  };
}
