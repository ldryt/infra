{ ... }:
{
  imports = [
    ./packages.nix
    ./helix.nix
    ./bash.nix
    ./git.nix
    ./dconf.nix
    ./firefox.nix
    ./thunderbird.nix
  ];

  home.username = "ldryt";
  home.homeDirectory = "/home/ldryt";

  home.stateVersion = "23.05";

  programs.home-manager.enable = true;
}
