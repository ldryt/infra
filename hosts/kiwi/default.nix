{ ... }: 
let secrets = import ../../secrets/git-crypt.nix;
in
{
  imports = [ 
    ./hardware.nix
    # ./services/ocis.nix
    ./services/authelia.nix
  ];

  nix.settings.system-features = [ "nix-command" "flakes" ];
  zramSwap.enable = true;
  networking.hostName = "kiwi";
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "yes";
  };

  sops.defaultSopsFile = ../../secrets/kiwi.yaml;
  sops.age.keyFile = "/var/lib/sops/age/main.key";

  users.mutableUsers = false;
  users.users.colon = {
    isSystemUser = true;
    group = "wheel";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOeroOCZerWNky5qXwi0uPV7+bOXHETDfXui0zc8fErp" ];
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  security.acme = {
    acceptTerms = true;
    defaults.email = secrets.ldryt.email;
  };
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    sslProtocols = "TLSv1.3";
    appendHttpConfig = ''
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;
    '';
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  services.postgresql = {
    enable = true;
    identMap = ''
      # ArbitraryMapName    systemUser    DBUser
        superuser_map       root          postgres
        superuser_map       postgres      postgres
    '';
    authentication = ''
      # type    database    DBuser    auth-method    optional_ident_map
        local   sameuser    all       peer           map=superuser_map
    '';
  };

  system.stateVersion = "23.05";
}
