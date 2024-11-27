{ config, ... }:
{
  # PRSTEYD-BFS3F7N-6AS245G-SFISD7N-CDZPWIK-MN6U7PN-NPW64SW-UTKRWA5
  sops.secrets."services/syncthing/key".owner = config.services.syncthing.user;
  sops.secrets."services/syncthing/cert".owner = config.services.syncthing.user;
  services.syncthing = {
    enable = true;
    dataDir = "/mnt/ssd1/syncthing_data";
    configDir = "/var/lib/syncthing_config";
    openDefaultPorts = true;
    key = config.sops.secrets."services/syncthing/key".path;
    cert = config.sops.secrets."services/syncthing/cert".path;
    settings = {
      devices = {
        "tinkerbell".id = "BRAQOO2-4MD5S4O-ORGTC3X-DEJDE3Q-YRK7V4E-VXXBR32-77PFW7P-G4Z6PAO";
      };
      folders = {
        "~/ldryt-documents-enc" = {
          id = "ldryt-documents";
          type = "receiveencrypted";
          devices = [ "tinkerbell" ];
        };
        "~/ldryt-pictures-enc" = {
          id = "ldryt-pictures";
          type = "receiveencrypted";
          devices = [ "tinkerbell" ];
        };
      };
    };
  };
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";
}
