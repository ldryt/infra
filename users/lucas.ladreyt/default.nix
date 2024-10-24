{ config, ... }:
{
  imports = [
    ../commons/vim.nix
    ../commons/bash.nix
    ../commons/alacritty.nix
    ../commons/i3.nix
    ../commons/clang-format.nix
    ../commons/packages/cli.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "lucas.ladreyt";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };
}
