{ config, pkgs, ... }:
{
  sops.secrets."services/nix-cache/priv-key" = { };
  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    bindAddress = "127.0.0.1";
    secretKeyFile = config.sops.secrets."services/nix-cache/priv-key".path;
  };
  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.nix-cache}" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString config.services.nix-serve.port}";
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
