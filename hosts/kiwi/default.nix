{ config, ... }:
let hidden = import ../../secrets/obfuscated.nix;
in {
  imports = [
    ./hardware.nix
    ./sops.nix

    ./services/ocis.nix
    ./services/authelia.nix

    ../../modules/nginx.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
  ];

  nix.settings.system-features = [ "nix-command" "flakes" ];
  zramSwap.enable = true;
  networking.hostName = "kiwi";
  networking.useDHCP = false;
  networking.interfaces."eth0".useDHCP = true;

  users.mutableUsers = false;
  users.users.colon = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets."users/colon/hashedPassword".path;
    openssh.authorizedKeys.keys = [ hidden.kiwi.ssh-pubkey ];
  };

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 3;
      memorySize = 2048;
      diskSize = 8192;
      forwardPorts = [ { from = "host"; host.port = 2222; guest.port = 22; } ];
      graphics = false;
      useHostCerts = true;
    };
  };
  security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
  environment.etc."sops_age_key".source = /etc/ssh/ssh_host_ed25519_key;

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  system.stateVersion = "23.05";
}
