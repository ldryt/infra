{ ... }:
{
  imports = [
    ./hardware
    ./services/streaming.nix
    ./services/backups.nix

    ../../modules/nix-settings.nix
    ../../modules/openssh.nix
    ../../modules/impermanence.nix
    ../../modules/colon-user.nix
  ];

  nixpkgs.config.allowUnfree = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/persist/sops_age_vidia.key";

  ldryt-infra.users.colon = {
    enable = true;
    uid = 1042;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEimIa93DgJAvncF6YEe5YctVdCPCNeEB3Bg79nhykpn terraform@vidia"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6wYQsWcmEu7zyET74f4rJEjeGVsBn91OIQXc2lV1gG colon@vidia"
    ];
  };

  users.users.ldryt = {
    isNormalUser = true;
    uid = 1000;
  };

  ldryt-infra.persist.users.ldryt.directories = [
    ".local/share/Steam"
    ".config/sunshine"
  ];

  networking = {
    enableIPv6 = false;
    useNetworkd = true;
    useDHCP = true;
  };

  time.timeZone = "Europe/Paris";

  system.stateVersion = "26.05";
}
