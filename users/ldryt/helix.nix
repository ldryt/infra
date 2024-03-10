{ pkgs, ... }: {
  home.sessionVariables.EDITOR = "hx";
  home.shellAliases."vim" = "hx";

  programs.helix = {
    enable = true;
    extraPackages = with pkgs;
      with nodePackages;
      with python311Packages; [
        vscode-langservers-extracted
        gopls
        gotools
        typescript
        typescript-language-server
        marksman
        nil
        nixfmt
        clang-tools
        lldb
        rust-analyzer
        rustfmt
        bash-language-server
        black
        python-lsp-server
        yaml-language-server
        taplo-lsp
        terraform-ls
      ];
    settings = {
      editor = {
        mouse = false;
        soft-wrap.enable = true;
        cursor-shape.insert = "bar";
      };
      theme = "gruvbox";
    };
    languages = {
      language = [
        {
          name = "rust";
          formatter.command = "rustfmt";
          auto-format = true;
        }
        {
          name = "nix";
          formatter.command = "nixfmt";
          auto-format = true;
        }
        {
          name = "go";
          formatter.command = "goimports";
          auto-format = true;
        }
        {
          name = "typescript";
          indent.tab-width = 4;
          indent.unit = " ";
          auto-format = true;
        }
        {
          name = "javascript";
          indent.tab-width = 4;
          indent.unit = " ";
          auto-format = true;
        }
        {
          name = "python";
          formatter = {
            command = "black";
            args = [ "--quiet" "-" ];
          };
          auto-format = true;
        }
      ];
    };
  };
}
