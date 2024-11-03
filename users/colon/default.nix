{ config, ... }:
{
  imports = [
    ../common/bash.nix
    ../common/vim.nix
    ../common/packages/cli.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "colon";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };
}
