{ ... }:
{
  imports = [
    ./hardware.nix
    ./users.nix
    ./locales.nix
    ./networking

    ../../modules/gnome.nix
    ../../modules/podman.nix
    ../../modules/nix-settings.nix

    ./services/windows-dockur.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_age_tinkerbell.key";

  system.stateVersion = "23.05";
}
