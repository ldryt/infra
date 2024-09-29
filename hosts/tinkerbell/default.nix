{ ... }:
{
  imports = [
    ./hardware
    ./networking
    ./users.nix
    ./locales.nix

    ../../modules/gnome.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix

    ./services/windows-dockur.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_tinkerbell.key";

  system.stateVersion = "23.05";
}
