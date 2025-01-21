{ config, ... }:
{
  sops.secrets."ssh/config".path = "${config.home.homeDirectory}/.ssh/config";
  programs.ssh.userKnownHostsFile = config.sops.secrets."ssh/known_hosts".path;
}
