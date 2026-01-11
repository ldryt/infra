{ ... }:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [
        "https://nix-cache.ldryt.dev?priority=10"
        "https://nix-community.cachix.org?priority=50"
        "https://s3.cri.epita.fr/cri-nix-cache.s3.cri.epita.fr?priority=90"
      ];
      extra-trusted-public-keys = [
        "nix-cache.ldryt.dev:LcILZm4hXqCkD31rz94/W+hhvap6ZZJZn9nt3gqvlDg="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nix.cri.epita.fr:qDIfJpZWGBWaGXKO3wZL1zmC+DikhMwFRO4RVE6VVeo="
      ];
    };

    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
