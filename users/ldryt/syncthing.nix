{ config, ... }:
{
  # BRAQOO2-4MD5S4O-ORGTC3X-DEJDE3Q-YRK7V4E-VXXBR32-77PFW7P-G4Z6PAO
  sops.secrets."services/syncthing/key" = { };
  sops.secrets."services/syncthing/cert" = { };

  # workaround to avoid syncthing-init.service dependency failure on boot
  systemd.user.services."syncthing".Unit.After = [ "sops-nix.service" ];

  services.syncthing = {
    enable = true;
    key = config.sops.secrets."services/syncthing/key".path;
    cert = config.sops.secrets."services/syncthing/cert".path;
    settings = {
      options = {
        urAccepted = -1;
        crashReportingEnabled = false;
      };
      devices = {
        "domus".id = "PRSTEYD-BFS3F7N-6AS245G-SFISD7N-CDZPWIK-MN6U7PN-NPW64SW-UTKRWA5";
        "rosetta".id = "27GKCTR-KWK6GEH-RQSNP6R-MENWWMA-XPKMLIN-HAKD2FC-BC5BBKX-HGVV2QX";
        "silvermist".id = "DURUBGK-S45UN27-6QQSHDA-7FWX3OS-4VCM4TD-NYMK6TV-JTEF742-VBTF7AZ";
      };
      folders = {
        "~/Sync/Vault" = {
          id = "ldryt-vault";
          devices = [
            "silvermist"
            "domus"
            "rosetta"
          ];
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
        "~/Sync/Notes" = {
          id = "ldryt-notes";
          devices = [
            "silvermist"
            "domus"
            "rosetta"
          ];
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
        "~/Documents/Sync" = {
          id = "ldryt-documents";
          devices = [
            "silvermist"
            "domus"
            "rosetta"
          ];
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
        "~/Pictures" = {
          id = "ldryt-pictures";
          devices = [
            "silvermist"
            "rosetta"
          ];
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
      };
    };
  };
}
