{ config, vars, ... }:
{
  sops.secrets."ssh/config".path = "${config.home.homeDirectory}/.ssh/config";
  sops.secrets."ssh/known_hosts".path = "${config.home.homeDirectory}/.ssh/known_hosts";

  programs.git = {
    enable = true;
    userName = "${vars.sensitive.users.ldryt.name} ${vars.sensitive.users.ldryt.surname}";
    userEmail = "git@ldryt.anonaddy.me";
    includes = [
      {
        contents.user.email = vars.sensitive.users.ldryt.work.email;
        condition = "hasconfig:remote.*.url:*@${vars.sensitive.users.ldryt.work.gitUrl}:**/**";
      }
    ];
  };
}
