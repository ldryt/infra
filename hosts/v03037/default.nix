{ ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./networking.nix
    ./users.nix
    ./klipper.nix

    ../../modules/nix-settings.nix
    ../../modules/openssh.nix
    ../../modules/chrony.nix
    ../../modules/dnscrypt.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/nix/sops_age_v03037.key";
  };

  system.stateVersion = "23.05";
}
