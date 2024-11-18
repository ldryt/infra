{ ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./networking.nix
    ./users.nix
    ./klipper.nix

    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/nix/sops_age_printer.key";
  };

  system.stateVersion = "23.05";
}
