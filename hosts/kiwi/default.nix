{ ... }:
let secrets = import ../../secrets/obfuscated.nix;
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
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [ secrets.kiwi.ssh-pubkey ];
  };

  virtualisation.vmVariant = {
    # following configuration is added only when building VM with build-vm
    virtualisation = {
      cores = 3;
      memorySize = 2048;
      diskSize = 8192;
      forwardPorts = [ { from = "host"; host.port = 2222; guest.port = 22; } ];
      graphics = false;
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  system.stateVersion = "23.05";
}
