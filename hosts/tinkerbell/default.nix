{ ... }:
{
  imports = [
    ./hardware
    ./networking
    ./users.nix
    ./locales.nix
    ./programs.nix

    ./services/virtualbox.nix
    ./services/docker.nix
    ./services/libvirt.nix

    ../../modules/greetd.nix
    ../../modules/sway.nix
    ../../modules/geoclue.nix
    ../../modules/steam.nix
    ../../modules/nix-settings.nix

    ../../modules/dns.nix
    ../../modules/impermanence.nix
  ];

  nixpkgs.config.allowUnfree = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_tinkerbell.key";

  system.stateVersion = "23.05";
}
