{
  lib,
  pkgs,
  config,
  ...
}:
let
  cacheUser = "nix-cache";
in
{
  sops.secrets."services/nix-cache/priv-key" = { };
  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    bindAddress = "127.0.0.1";
    secretKeyFile = config.sops.secrets."services/nix-cache/priv-key".path;
  };
  services.nginx =
    let
      nixUpstream = "nix-serve";
    in
    {
      upstreams."${nixUpstream}" = {
        servers = {
          "${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}" = { };
        };
        extraConfig = ''
          keepalive 128;
        '';
      };
      appendHttpConfig = ''
        proxy_cache_path /var/cache/nginx/nix_cache levels=1:2 keys_zone=nix_cache:512m max_size=5g inactive=60m use_temp_path=off;
      '';
      virtualHosts."${config.ldryt-infra.dns.records.nix-cache}" = {
        forceSSL = true;
        enableACME = true;
        kTLS = true;
        extraConfig = ''
          client_max_body_size 0;
          proxy_read_timeout 30m;
          proxy_buffering on;
          proxy_buffer_size 16k;
          proxy_buffers 32 16k;
        '';
        locations = {
          "/" = {
            proxyPass = "http://${nixUpstream}";
            extraConfig = ''
              proxy_set_header Connection "";
            '';
          };
          "~ \\.narinfo$" = {
            proxyPass = "http://${nixUpstream}";
            extraConfig = ''
              proxy_cache nix_cache;
              proxy_cache_valid 200 45m;
              proxy_cache_valid 404 15m;
              proxy_set_header Connection "";
            '';
          };
        };
      };
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
  nix.gc.automatic = lib.mkForce false;
}
