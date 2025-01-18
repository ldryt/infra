{ pkgs, modulesPath, ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./networking.nix
    ./users.nix

    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_domus.key";

  system.stateVersion = "24.05";
}
