{ pkgs, ... }:
{
  home.sessionVariables."NIXOS_OZONE_WL" = "1";
  home.packages = with pkgs; [
    direnv
    nil
    nixfmt-rfc-style
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      # VSCode utilities
      mkhl.direnv

      # VSCode Theme
      jdinhlife.gruvbox

      # Nix support
      jnoortheen.nix-ide

      # MD support
      yzhang.markdown-all-in-one

      # Python support
      ms-python.python
      ms-pyright.pyright
      ms-python.black-formatter
      ms-python.isort

      # Terraform support
      hashicorp.terraform

      # Go support
      golang.go

      # Rust support
      rust-lang.rust-analyzer
    ];

    enableExtensionUpdateCheck = false;
    enableUpdateCheck = false;

    userSettings = {
      "git.confirmSync" = false;
      "workbench.colorTheme" = "Gruvbox Dark Hard";
      "vim.useSystemClipboard" = true;
      "window.zoomLevel" = 1;
      "nix.formatterPath" = "nixfmt";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
    };
  };
}
