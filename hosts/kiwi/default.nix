{ ... }: 
let secrets = import ../../secrets/git-crypt.nix;
in
{
  imports = [ 
    ./hardware.nix
    ./sops.nix
    
    # ./services/ocis.nix
    ./services/authelia.nix

    ../../modules/nginx.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
  ];

  nix.settings.system-features = [ "nix-command" "flakes" ];
  zramSwap.enable = true;
  networking.hostName = "kiwi";

  users.mutableUsers = false;
  users.users.colon = {
    isSystemUser = true;
    group = "wheel";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOeroOCZerWNky5qXwi0uPV7+bOXHETDfXui0zc8fErp" ];
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  system.stateVersion = "23.05";
}
