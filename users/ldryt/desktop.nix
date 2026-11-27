{ config, ... }:
{
  imports = [
    ../common/clang-format.nix
    ../common/c.nix
    ../common/vscode.nix
    ../common/zen-browser.nix
    ../common/ghostty.nix

    ./gnome.nix
    ./packages.nix
    ./firefox.nix
    ./thunderbird.nix
    ./syncthing.nix
  ];

  programs.home-manager.enable = true;

  sops = {
    defaultSymlinkPath = "${config.home.homeDirectory}/.sops/secrets";
    defaultSecretsMountPoint = "${config.home.homeDirectory}/.sops/secrets.d";
  };
}
