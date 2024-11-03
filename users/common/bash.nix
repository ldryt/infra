{ ... }:
{
  programs.bash.enable = true;
  programs.bash = {
    enableCompletion = true;
    bashrcExtra = ''
      export PS1='$(git branch &>/dev/null; if [ $? -eq 0 ]; then \
      echo "\[\e[1m\]\u@\h\[\e[0m\]: \W [\[\e[34m\]$(git branch \
        | grep ^* | sed s/\*\ //)\[\e[0m\]\
      $(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
        if [ "$?" -ne "0" ]; then \
      echo "\[\e[1;31m\]*\[\e[0m\]"; fi)] \$ "; else \
      echo "\[\e[1m\]\u@\h\[\e[0m\]: \W \$ "; fi )'
    '';
  };
}
