{ ... }:
let
  sensitive = import ./sensitive.gitcrypt.nix;
in
{
  programs.git = {
    enable = true;
    userName = "${sensitive.name} ${sensitive.surname}";
    userEmail = "git@ldryt.anonaddy.me";
    includes = [
      {
        contents.user.email = sensitive.workEmail;
        condition = "hasconfig:remote.*.url:*@${sensitive.workGit}:**/**";
      }
    ];
  };
}
