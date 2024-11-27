{ ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./networking
    ./users.nix

    ../../modules/nix-settings.nix
    ../../modules/openssh.nix

    ./services/syncthing.nix
    ./services/syncthing-relay.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_rpi.key";

  system.stateVersion = "23.05";
}
