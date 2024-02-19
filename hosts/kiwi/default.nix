{ inputs, config, ... }:
let hidden = import ../../secrets/obfuscated.nix;
in {
  imports = [
    ./hardware.nix
    ./sops.nix

    ./services/ocis.nix
    ./services/authelia.nix
    ./services/vaultwarden.nix
    ./services/immich.nix

    ../../modules/caddy.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
  ];

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
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

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
