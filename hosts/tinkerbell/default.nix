{ ... }:
{
  imports = [
    ./hardware
    ./networking
    ./users.nix
    ./locales.nix

    ../../modules/gnome.nix
    ../../modules/power.nix
    ../../modules/nix-settings.nix

    ./services/windows-dockur.nix
  ];

  virtualisation.virtualbox.host.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_tinkerbell.key";

  programs.fuse.userAllowOther = true; # needed for home-manager impermanence

  environment.persistence."/nix/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/cache/powertop"
      "/etc/secureboot"
      "/var/lib/fprint"
    ];
    files = [ "/etc/machine-id" ];
  };

  system.stateVersion = "23.05";
}
