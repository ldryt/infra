{ config, ... }:
{
  imports = [
    ../commons/helix.nix
    ../commons/bash.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "lucas.ladreyt";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };
}
