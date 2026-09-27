{ config, ... }:
{
  imports = [
    ../common/bash.nix
    ../common/vim.nix
    ../common/packages/cli.nix
    ../common/helix/full.nix
    ../common/git.nix
  ];

  programs.home-manager.enable = true;
  programs.tmux.enable = true;
  programs.bash.initExtra = ''
    if [[ $- == *i* && -z $TMUX ]]; then
      exec tmux new-session -A -s remote
    fi
  '';

  home = {
    username = "ldryt";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };
}
