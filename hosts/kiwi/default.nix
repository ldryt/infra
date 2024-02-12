{ config, pkgs, ... }:
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
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets."users/colon/hashedPassword".path;
    openssh.authorizedKeys.keys = [ hidden.kiwi.ssh-pubkey ];
  };

  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/glouton" = {
    device = hidden.kiwi.smb.glouton.shareName;
    fsType = "cifs";
    options = ["x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,credentials=${config.sops.secrets."system/smb/glouton/credentials".path},uid=1000,gid=100"];
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

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  system.stateVersion = "23.05";
}
