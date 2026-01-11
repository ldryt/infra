{ pkgs, config, ... }:
let
  cacheUser = "nix-cache";
in
{
  sops.secrets."services/nix-cache/priv-key" = { };
  services.nix-serve = {
    enable = true;
    bindAddress = "127.0.0.1";
    secretKeyFile = config.sops.secrets."services/nix-cache/priv-key".path;
  };
  services.nginx.virtualHosts."${config.ldryt-infra.dns.records.nix-cache}" = {
    forceSSL = true;
    enableACME = true;
    kTLS = true;
    extraConfig = ''
      client_max_body_size 0;
      proxy_read_timeout 900s;
    '';
    locations."/".proxyPass =
      "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
  };
  users.groups."${cacheUser}" = { };
  users.users."${cacheUser}" = {
    isSystemUser = true;
    shell = pkgs.bash;
    group = cacheUser;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxd7esI84tSbA6QBly3nVNP0EZSK1M7Nl735D6Bc5Rj nix-cache@gha"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8BgnNMkYkopvySMTAxBSIMw+LNh51Bxf5r8ni711tD nix-cache@tinkerbell"
    ];
  };
  nix.settings.trusted-users = [ cacheUser ];
  services.openssh.extraConfig = ''
    Match User ${cacheUser}
      ForceCommand ${config.nix.package}/bin/nix-store --serve --write
  '';
}
