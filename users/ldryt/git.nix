{ config, vars, ... }:
{
  sops.secrets."ssh/config".path = "${config.home.homeDirectory}/.ssh/config";
  sops.secrets."ssh/known_hosts".path = "${config.home.homeDirectory}/.ssh/known_hosts";

  programs.git = {
    enable = true;
    userName = "${vars.sensitive.users.ldryt.name} ${vars.sensitive.users.ldryt.surname}";
    userEmail = "git@ldryt.anonaddy.me";
  };
}
