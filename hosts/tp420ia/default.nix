{ ... }:
{
  imports = [
    ./hardware
    ./networking
    ./users.nix

    ../../modules/nix-settings.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_tp420ia.key";

  environment.persistence.tp420ia = {
    persistentStoragePath = "/nix/persist";
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/cache/powertop"
      "/etc/secureboot"
    ];
    files = [ "/etc/machine-id" ];
  };

  system.stateVersion = "23.05";
}
