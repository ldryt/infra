{ config, ... }:
{
  imports = [
    ../commons/bash.nix
    ../commons/vim.nix
    ../commons/packages/cli.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "colon";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };
}
