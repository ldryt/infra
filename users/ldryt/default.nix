{ config, ... }:
{
  imports = [
    ../common/bash.nix
    ../common/vim.nix
    ../common/helix/full.nix
    ../common/clang-format.nix
    ../common/c.nix
    ../common/git.nix
    ../common/vscode.nix

    ./sway.nix
    ./packages.nix
    ./firefox.nix
    ./thunderbird.nix
    ./syncthing.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "ldryt";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "23.05";
  };

  sops = {
    age.keyFile = "/nix/persist/sops_age_ldryt.key";
    defaultSopsFile = ./secrets.yaml;
    defaultSymlinkPath = "${config.home.homeDirectory}/.sops/secrets";
    defaultSecretsMountPoint = "${config.home.homeDirectory}/.sops/secrets.d";
  };
}
