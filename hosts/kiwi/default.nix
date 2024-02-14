{ inputs, config, pkgs, ... }:
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

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.settings.trusted-users = [ "root" "colon" ];
  zramSwap.enable = true;
  networking.hostName = "kiwi";
  networking.useDHCP = false;
  networking.interfaces."eth0".useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  users.mutableUsers = false;
  users.users.colon = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets."users/colon/hashedPassword".path;
    openssh.authorizedKeys.keys = [ hidden.kiwi.ssh-pubkey ];
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/glouton" = {
    device = hidden.kiwi.smb.glouton.shareName;
    fsType = "cifs";
    options = [
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,credentials=${
        config.sops.secrets."system/smb/glouton/credentials".path
      },uid=1000,gid=100,cache=loose,fsc"
    ];
  };

  system.stateVersion = "23.05";
}
