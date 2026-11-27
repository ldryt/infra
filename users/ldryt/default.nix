{ config, ... }:
{
  imports = [
    ../common/bash.nix
    ../common/vim.nix
    ../common/helix/full.nix
    ../common/git.nix
    ../common/packages/cli.nix
    ../common/pi
  ];

  home = {
    username = "ldryt";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };
}
