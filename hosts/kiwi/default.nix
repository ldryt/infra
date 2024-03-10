{ inputs, config, ... }:
let hidden = import ../../secrets/obfuscated.nix;
in {
  imports = [
    ./hardware.nix

    ./services/ocis.nix
    ./services/authelia.nix
    ./services/vaultwarden.nix
    ./services/immich.nix
    ./services/velocity.nix

    ../../modules/caddy.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/fail2ban.nix
  ];

  sops.defaultSopsFile = ../../secrets/kiwi.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_kiwi_age_key";

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "colon" ];
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  time.timeZone = "Etc/UTC";
  networking = {
    hostName = "kiwi";
    useDHCP = false;
    interfaces."eth0".useDHCP = true;
    interfaces."enp7s0".useDHCP = true;
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
      openssh.authorizedKeys.keys = [ hidden.kiwi.ssh-pubkey ];
    };
  };
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "23.05";
}
