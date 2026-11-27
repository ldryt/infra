{ lib, ... }:
{
  programs.vim.defaultEditor = lib.mkForce false;
  programs.helix.defaultEditor = true;

  programs.bash.initExtra = ''
    if [[ -z $TMUX ]]; then
      exec tmux new-session -A -s remote
    fi
  '';

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g extended-keys on
      set -g extended-keys-format csi-u
      bind-key -n PageUp if-shell -F '#{alternate_on}' 'send-keys PageUp' 'copy-mode -eu'
    '';
  };
}
