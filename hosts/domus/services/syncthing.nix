{ config, ... }:
{
  # PRSTEYD-BFS3F7N-6AS245G-SFISD7N-CDZPWIK-MN6U7PN-NPW64SW-UTKRWA5
  sops.secrets."services/syncthing/key".owner = config.services.syncthing.user;
  sops.secrets."services/syncthing/cert".owner = config.services.syncthing.user;

  services.syncthing = {
    enable = true;
    dataDir = "/var/lib/syncthing/data";
    configDir = "/var/lib/syncthing/config";
    openDefaultPorts = true;
    key = config.sops.secrets."services/syncthing/key".path;
    cert = config.sops.secrets."services/syncthing/cert".path;
    settings = {
      options = {
        localAnnounceEnabled = false;
      };
      devices = {
        "tinkerbell".id = "BRAQOO2-4MD5S4O-ORGTC3X-DEJDE3Q-YRK7V4E-VXXBR32-77PFW7P-G4Z6PAO";
        "rosetta".id = "27GKCTR-KWK6GEH-RQSNP6R-MENWWMA-XPKMLIN-HAKD2FC-BC5BBKX-HGVV2QX";
        "silvermist".id = "DURUBGK-S45UN27-6QQSHDA-7FWX3OS-4VCM4TD-NYMK6TV-JTEF742-VBTF7AZ";
      };
      folders = {
        "~/ldryt-notes" = {
          id = "ldryt-notes";
          devices = [
            "tinkerbell"
            "silvermist"
            "rosetta"
          ];
        };
        "~/ldryt-vault" = {
          id = "ldryt-vault";
          devices = [
            "tinkerbell"
            "silvermist"
            "rosetta"
          ];
        };
        "~/ldryt-documents" = {
          id = "ldryt-documents";
          devices = [
            "tinkerbell"
            "silvermist"
            "rosetta"
          ];
        };
      };
    };
  };
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";
}
