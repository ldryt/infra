{ lib, pkgs, ... }:
{
  home.sessionVariables."NIXOS_OZONE_WL" = "1";
  home.packages = with pkgs; [
    direnv

    nil
    nixfmt-rfc-style

    yarn
    eslint
    nodejs
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "vscode"
      "vscode-extension-ms-vscode-cpptools"
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

      # JavaScript
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
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

      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.rulers" = [ 80 ];
      "eslint.useFlatConfig" = true;
      "eslint.validate" = [
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
      ];
      "eslint.probe" = [
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
      ];
      "eslint.run" = "onType";
      "editor.codeActionsOnSave" = {
        "source.fixAll.eslint" = "explicit";
      };
    };
  };
}
