{ config, ... }:
{
  imports = [
    ../common/vim.nix
    ../common/bash.nix
    ../common/i3/i3.nix
    ../common/alacritty.nix
    ../common/clang-format.nix
    ../common/packages/cli.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "lucas.ladreyt";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };
}
