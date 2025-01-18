{ ... }:
{
  programs.git = {
    enable = true;
    extraConfig = {
      push.autoSetupRemote = true;
      alias."pretty-log" =
        "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
    };
    userName = "Lucas Ladreyt";
    userEmail = "git@ldryt.anonaddy.me";
    includes = [
      {
        contents.user.email = "lucas.ladreyt@epita.fr";
        condition = "hasconfig:remote.*.url:*@*.epita.fr:**/**";
      }
    ];
  };
}
