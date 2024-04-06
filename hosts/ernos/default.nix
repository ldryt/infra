{
  config,
  lib,
  pkgs,
  inputs,
  vars,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disks.nix
    ./services/mc.nix
    ../../modules/openssh.nix
    ../../modules/podman.nix
    ../../modules/fail2ban.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_age_bozi.key";

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  time.timeZone = "Etc/UTC";
  networking = {
    hostName = "bozi";
    useDHCP = false;
    interfaces."eth0".useDHCP = true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  users.users.root.openssh.authorizedKeys.keys = [ vars.sensitive.users.root.sshPubKey ];

  system.stateVersion = "23.11";
}
