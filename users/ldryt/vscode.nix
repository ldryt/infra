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
    package = pkgs.vscode;
    extensions = with pkgs.vscode-extensions; [
      # VSCode utilities
      mkhl.direnv

      # VSCode Theme
      jdinhlife.gruvbox

      # Nix support
      jnoortheen.nix-ide

      # C++ support
      ms-vscode.cpptools
      xaver.clang-format

      # Flex and Bison support
      daohong-emilio.yash

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
      "workbench.colorTheme" = "Gruvbox Dark Hard";
      "window.zoomLevel" = 1;
      "editor.minimap.enabled" = false;

      "git.confirmSync" = false;
      "editor.formatOnSave" = true;

      "nil.formatting.command" = "nixfmt";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";

      "[cpp]" = {
        "editor.defaultFormatter" = "xaver.clang-format";
      };
    };
  };
}
