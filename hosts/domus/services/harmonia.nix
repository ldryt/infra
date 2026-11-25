{ config, ... }:
{
  sops.secrets."services/nix-cache/priv-key".restartUnits = [ "harmonia.service" ];

  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ config.sops.secrets."services/nix-cache/priv-key".path ];
    settings = {
      bind = "127.0.0.1:5000";
      enable_compression = true;
    };
  };

  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.nix-cache}" = {
    forceSSL = true;
    enableACME = true;
    extraConfig = ''
      access_log /var/log/nginx/nix-cache.access.log;
      error_log /var/log/nginx/nix-cache.error.log;
    '';
    locations."/".proxyPass = "http://${config.services.harmonia.cache.settings.bind}";
  };
  nix.sshServe = {
    enable = true;
    write = true;
    trusted = true;
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwlnngGBuco81UaOZZTmNfKuoe82MMNDWPKM1jFOb/M nix-cache@gha"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8BgnNMkYkopvySMTAxBSIMw+LNh51Bxf5r8ni711tD nix-cache@tinkerbell"
    ];
  };
}
