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

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "luke.ldryt.dev";
      system = "aarch64-linux";
      maxJobs = 4;
      sshUser = "colon";
      sshKey = "/home/ldryt/.ssh/colon@luke.pem";
      supportedFeatures = [ "big-parallel" ];
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUd2aVJCUzhCOHhnVEJLQXowOWo4akhNN2VOcmR1MU5FL0VrZGVhTFhEUmUgcm9vdEBsdWtlCg==";
    }
  ];
  nix.settings.builders-use-substitutes = true;
}
