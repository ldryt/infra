{ config, ... }:
{
  sops.secrets."ssh/config".path = "${config.home.homeDirectory}/.ssh/config";
  sops.secrets."ssh/known_hosts".path = "${config.home.homeDirectory}/.ssh/known_hosts";
}
