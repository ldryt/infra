{ pkgs, ... }: {
  home.sessionVariables.EDITOR = "hx";
  home.shellAliases."vim" = "hx";

  programs.helix = {
    enable = true;
    extraPackages = with pkgs;
      with nodePackages;
      with python311Packages; [
        # TeX
        texlab
        texliveMedium

        # Rust
        rust-analyzer
        rustfmt
        clang-tools
        lldb

        # Nix
        nil
        nixfmt

        # GO
        gopls
        gotools

        # Typescript
        typescript
        typescript-language-server

        # Bash
        bash-language-server

        # Python
        black
        python-lsp-server

        # YAML
        yaml-language-server

        # TOML
        taplo-lsp

        # Markdown
        marksman

        # HCL
        terraform-ls

        # Misc
        vscode-langservers-extracted
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
      language-server = {
        texlab.config.texlab = {
          build = {
            onSave = true;
            forwardSearchAfter = true;
          };
          forwardSearch = {
            executable = "evince";
            args = [ "%p" ];
          };
          chktex = {
            onOpenAndSave = true;
            onEdit = true;
          };
        };
      };
      language = [
        {
          name = "latex";
          auto-format = true;
        }
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
