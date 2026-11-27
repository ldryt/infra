{
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
