{ ... }:
{
  programs.git = {
    enable = true;
    extraConfig = {
      push.autoSetupRemote = true;
    };
    userName = "Lucas Ladreyt";
    userEmail = "git@ldryt.anonaddy.me";
    includes = [
      {
        contents.user.email = "lucas.ladreyt@epita.fr";
        condition = "hasconfig:remote.*.url:*@git.forge.epita.fr:**/**";
      }
    ];
  };
}
