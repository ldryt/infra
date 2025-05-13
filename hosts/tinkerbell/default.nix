{ ... }:
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
    ../../modules/nix-settings.nix

    ./services/windows-dockur.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  virtualisation.virtualbox.host.enable = true;
  virtualisation.docker.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_tinkerbell.key";

  environment.persistence."/nix/persist" = {
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
      ];
      files = [
        ".config/monitors.xml"
        ".config/mimeapps.list"
      ];
    };
  };

  system.stateVersion = "23.05";
}
