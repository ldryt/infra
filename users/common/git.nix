{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Lucas Ladreyt";
        email = "ldryt@posteo.com";
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnmemonicPrefix = true;
        renames = true;
      };
      core = {
        fsmonitor = true;
        untrackedCache = true;
      };
      help.autocorrect = "prompt";
      commit.verbose = true;
      merge.conflictstyle = "zdiff3";
      pull.rebase = true;
      alias."pretty-log" =
        "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
    };
    includes = [
      {
        contents.user.email = "lucas.ladreyt@epita.fr";
        condition = "hasconfig:remote.*.url:*@*.epita.fr:**/**";
      }
      {
        contents.user.email = "lucas.ladreyt@obspm.fr";
        condition = "hasconfig:remote.*.url:*@*.obspm.fr:**/**";
      }
    ];
  };
}
