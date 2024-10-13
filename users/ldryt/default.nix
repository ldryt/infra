{ config, ... }:
{
  imports = [
    ../commons/bash.nix
    ../commons/vim.nix
    ../commons/clang-format.nix
    ../commons/c.nix

    ./packages.nix
    ./git.nix
    ./ssh.nix
    ./gnome.nix
    ./firefox.nix
    ./thunderbird.nix
    ./vscodium.nix
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

  home.persistence."/nix/persist/home/ldryt" = {
    allowOther = true;
    directories = [
      "Documents"
      "Downloads"
      "Music"
      "Pictures"
      "Videos"
      "VirtualBox VMs"
      ".ssh"
      ".keyring"
      ".local/share/direnv"
      ".local/share/keyrings"
    ];
  };
}
