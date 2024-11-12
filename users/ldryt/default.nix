{ config, ... }:
{
  imports = [
    ../common/bash.nix
    ../common/vim.nix
    ../common/clang-format.nix
    ../common/c.nix
    ../common/alacritty.nix

    ./gnome.nix
    ./packages.nix
    ./git.nix
    ./ssh.nix
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
      ".config/vesktop"
      ".config/SuperSlicer"
      ".thunderbird"
      ".terraform.d"
      ".config/dconf"
    ];
  };
}
