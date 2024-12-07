{ config, ... }:
let
  dataDir = "Sync";
in
{
  # BRAQOO2-4MD5S4O-ORGTC3X-DEJDE3Q-YRK7V4E-VXXBR32-77PFW7P-G4Z6PAO
  sops.secrets."services/syncthing/key" = { };
  sops.secrets."services/syncthing/cert" = { };

  services.syncthing = {
    enable = true;
    key = config.sops.secrets."services/syncthing/key".path;
    cert = config.sops.secrets."services/syncthing/cert".path;
    settings = {
      devices = {
        "rpi".id = "PRSTEYD-BFS3F7N-6AS245G-SFISD7N-CDZPWIK-MN6U7PN-NPW64SW-UTKRWA5";
      };
      folders = {
        "~/${dataDir}/documents" = {
          id = "ldryt-documents";
          devices = [ "rpi" ];
        };
        "~/${dataDir}/pictures" = {
          id = "ldryt-pictures";
          devices = [ "rpi" ];
        };
      };
    };
  };
}
