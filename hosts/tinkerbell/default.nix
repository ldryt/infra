{ ... }:
{
  imports = [
    ./hardware
    ./networking
    ./users.nix
    ./locales.nix

    ./services/virtualbox.nix
    ./services/docker.nix

    ../../modules/greetd.nix
    ../../modules/sway.nix
    ../../modules/geoclue.nix
    ../../modules/steam.nix
    ../../modules/nix-settings.nix
  ];

  nixpkgs.config.allowUnfree = true;

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
      "/var/cache/tuigreet"
    ];
    files = [ "/etc/machine-id" ];

    users.ldryt = {
      directories = [
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        "Sync"
        ".local/state/syncthing"
        ".ssh"
        ".local/share/direnv"
        ".local/share/wluma"
        ".config/SuperSlicer"
        ".mozilla"
        ".thunderbird"
        ".terraform.d"
        ".config/dconf"
        ".local/share/Steam"
        ".config/JetBrains"
        ".config/keepassxc"
        ".cache/keepassxc"
        ".config/obsidian"
        ".parsec"
        ".parsec-persistent"
        ".local/share/TelegramDesktop"
        ".local/share/PrismLauncher"
        ".config/Slack"
      ];
      files = [
        ".config/digikamrc"
        ".config/digikam_systemrc"
      ];
    };
  };

  environment.persistence."/nix/tmp".directories = [
    "/tmp"
    "/var/tmp"
  ];

  programs.nix-ld.enable = true;

  system.stateVersion = "23.05";
}
