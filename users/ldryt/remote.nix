{ config, ... }:
{
  imports = [
    ../common/bash.nix
    ../common/vim.nix
    ../common/packages/cli.nix
    ../common/helix/full.nix
    ../common/git.nix
  ];

  home = {
    username = "ldryt";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };

  programs.bash.initExtra = ''
    if [[ -z $TMUX ]]; then
      exec tmux new-session -A -s remote
    fi
  '';

  programs.tmux = {
    enable = true;
    extraConfig = ''
      bind-key -n PageUp if-shell -F '#{alternate_on}' 'send-keys PageUp' 'copy-mode -eu'
    '';
  };
}
