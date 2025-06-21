{ lib, ... }:
{
  imports = [
    ./hardware
    ./networking
    ./users.nix
    ./locales.nix

    ../../modules/greetd.nix
    ../../modules/sway.nix
    ../../modules/geoclue.nix
    ../../modules/steam.nix
    ../../modules/net1.nix
    ../../modules/nix-settings.nix

    ./services/windows-dockur.nix
    ./services/libvirt-single-gpu-passthrough.nix
  ];

  nixpkgs.config.allowUnfree = true;

  virtualisation.virtualbox.host.enable = true;
  virtualisation.docker.enable = true;
  # https://discourse.nixos.org/t/disable-a-systemd-service-while-having-it-in-nixoss-conf/12732/4
  systemd.services.docker.wantedBy = lib.mkForce [ ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_tinkerbell.key";

  environment.persistence.tinkerbell = {
    persistentStoragePath = "/nix/persist";
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/cache/powertop"
      "/etc/secureboot"
      "/var/lib/fprint"
      "/var/lib/containers"
      "/var/lib/docker"
      "/var/cache/tuigreet"

      # Quick and dirty fix for large nix builds
      "/tmp"
    ];
    files = [ "/etc/machine-id" ];

    users.ldryt = {
      directories = [
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        "VirtualBox VMs"
        ".config/VirtualBox"
        "Sync"
        ".local/state/syncthing"
        ".ssh"
        ".keyring"
        ".local/share/direnv"
        ".local/share/keyrings"
        ".config/vesktop"
        ".config/SuperSlicer"
        ".mozilla"
        ".thunderbird"
        ".terraform.d"
        ".config/dconf"
        ".local/share/Steam"
        ".config/JetBrains"
        ".config/evolution"
        ".config/goa-1.0"
        ".cache/tracker3"
        ".config/keepassxc"
        ".cache/keepassxc"
        ".config/obsidian"
        ".local/share/wluma"
        "GNS3"
        ".local/share/GNS3"
        ".parsec"
        ".parsec-persistent"
        ".local/share/TelegramDesktop"
        ".config/Slack"
      ];
      files = [
        ".config/monitors.xml"
        ".config/mimeapps.list"
      ];
    };
  };

  system.stateVersion = "23.05";
}
