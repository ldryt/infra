{ pkgs, ... }:
{
  home.sessionVariables."NIXOS_OZONE_WL" = "1";

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      # VSCode utilities
      vscodevim.vim
      mkhl.direnv

      # VSCode Theme
      jdinhlife.gruvbox

      # MD support
      yzhang.markdown-all-in-one

      # Python support
      ms-python.python
      ms-pyright.pyright
      ms-python.black-formatter
      ms-python.isort
    ];

    enableExtensionUpdateCheck = false;
    enableUpdateCheck = false;

    userSettings = {
      "git.confirmSync" = false;
      "workbench.colorTheme" = "Gruvbox Dark Medium";
      "vim.useSystemClipboard" = true;
      "window.zoomLevel" = 1;
    };
  };
}
