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
    age.keyFile = "/nix/sops_age_v03037.key";
  };

  system.stateVersion = "23.05";
}
