{ config, ... }:
{
  imports = [
    ../commons/bash.nix
    ../commons/helix.nix

    ./packages.nix
    ./git.nix
    ./ssh.nix
    ./gnome.nix
    ./firefox.nix
    ./thunderbird.nix
    ./vscodium.nix
    ./nextcloud.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "ldryt";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.keyring/sops_age_ldryt.key";
    defaultSopsFile = ./secrets.yaml;
    defaultSymlinkPath = "${config.home.homeDirectory}/.sops/secrets";
    defaultSecretsMountPoint = "${config.home.homeDirectory}/.sops/secrets.d";
  };
}
