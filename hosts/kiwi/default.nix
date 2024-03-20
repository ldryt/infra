{ inputs, config, vars, ... }: {
  imports = [
    ./hardware.nix

    ./services/ocis.nix
    ./services/authelia.nix
    ./services/vaultwarden.nix
    ./services/immich.nix

    ../../modules/fail2ban.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_age_kiwi.key";

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "colon" ];
      auto-optimise-store = true;
      registry.nixpkgs.flake = inputs.nixpkgs;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  services.caddy = {
    enable = true;
    email = vars.sensitive.services.caddy.email;
  };

  time.timeZone = "Etc/UTC";
  networking = {
    hostName = "kiwi";
    useDHCP = false;
    interfaces."eth0".useDHCP = true;
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

  sops.secrets."users/colon/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.colon = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPasswordFile =
        config.sops.secrets."users/colon/hashedPassword".path;
      openssh.authorizedKeys.keys = [ vars.sensitive.users.colon.sshPubKey ];
    };
  };
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "23.05";
}
