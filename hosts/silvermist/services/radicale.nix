{ config, ... }:
let
  dns = builtins.fromJSON (builtins.readFile ../../../dns.json);
  internalPort = "5232";
  dataDir = "/var/lib/radicale/collections";
in
{
  environment.persistence.silvermist.directories = [ dataDir ];

  sops.secrets."backups/restic/repos/radicale/password" = { };
  ldryt-infra.backups.repos.radicale = {
    passwordFile = config.sops.secrets."backups/restic/repos/radicale/password".path;
    paths = [ dataDir ];
  };

  sops.secrets."services/radicale/htpasswd".owner = config.users.users.radicale.name;
  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "127.0.0.1:${internalPort}" ];
      auth = {
        type = "htpasswd";
        htpasswd_filename = config.sops.secrets."services/radicale/htpasswd".path;
        htpasswd_encryption = "bcrypt";
      };
      storage.filesystem_folder = dataDir;
    };
  };

  services.nginx.virtualHosts."${dns.subdomains.radicale}.${dns.zone}" = {
    enableACME = true;
    forceSSL = true;
    kTLS = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${internalPort}";
      extraConfig = ''
        proxy_set_header  X-Script-Name /;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass_header Authorization;
      '';
    };
  };
}
