{ ... }:
{
  programs.bash.enable = true;
  programs.bash = {
    enableCompletion = true;
    bashrcExtra = ''
      export PS1='$(
        if [ -n "$IN_NIX_SHELL" ]; then
            echo -n "\[\e[1;36m\](nix)\[\e[0m\] ";
        fi;
        if git rev-parse --is-inside-work-tree &>/dev/null; then
            BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
            if [ -n "$(git status --porcelain -uno 2>/dev/null)" ]; then
                DIRTY="\[\e[1;31m\]*\[\e[0m\]"
            else
                DIRTY=""
            fi

            echo "\[\e[1m\]\u@\h\[\e[0m\]: \W [\[\e[34m\]$BRANCH\[\e[0m\]$DIRTY] \$ "
        else
            echo "\[\e[1m\]\u@\h\[\e[0m\]: \W \$ "
        fi
      )'
    '';
  };
}
