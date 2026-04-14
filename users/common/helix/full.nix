{ pkgs, ... }:
{
  imports = [
    ./minimal.nix
    ../c.nix
  ];

  programs.helix = {
    extraPackages =
      with pkgs;
      with nodePackages;
      with python311Packages;
      [
        # TeX
        texlab
        ltex-ls
        evince

        # Rust
        rust-analyzer
        rustfmt
        clang-tools
        lldb

        # GO
        gopls
        gotools

        # Typescript
        vscode-langservers-extracted
        prettier
        typescript
        typescript-language-server

        # Bash
        bash-language-server

        # Python
        black
        pyright

        # Markdown
        marksman

        # HCL
        terraform-ls

        # Misc
        dockerfile-language-server
        fortls
        taplo
        yaml-language-server
        bash-language-server
        neocmakelsp
        mesonlsp
      ];
    languages = {
      language-server = {
        typescript-language-server = {
          command = "typescript-language-server";
          args = [ "--stdio" ];
          config.tsserver.path = "${pkgs.nodePackages.typescript}/bin/tsserver";
        };
        eslint = {
          command = "vscode-eslint-language-server";
          args = [ "--stdio" ];
          config = {
            format = false;
            packageManages = "npm";
            nodePath = "";
            workingDirectory.mode = "auto";
            onIgnoredFiles = "off";
            run = "onType";
            validate = "on";
            useESLintClass = false;
            experimental = { };
            codeAction = {
              disableRuleComment = {
                enable = true;
                location = "separateLine";
              };
              showDocumentation.enable = true;
            };
          };
        };
        texlab.config.texlab = {
          build = {
            onSave = true;
            forwardSearchAfter = true;
            executable = "latexmk";
            args = [
              "-interaction=nonstopmode"
              "-pdf"
              "-lualatex"
              "%f"
            ];
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
          language-servers = [
            "texlab"
            "ltex"
          ];
          auto-format = true;
          auto-pairs = {
            "(" = ")";
            "`" = "'";
            "{" = "}";
          };
        }
        {
          name = "rust";
          formatter.command = "rustfmt";
          auto-format = true;
        }
        {
          name = "go";
          formatter.command = "goimports";
          auto-format = true;
        }
        {
          name = "javascript";
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = [ "format" ];
            }
            {
              name = "eslint";
              except-features = [ "format" ];
            }
          ];
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "typescript"
            ];
          };
        }
        {
          name = "python";
          language-servers = [ "pyright" ];
          formatter = {
            command = "black";
            args = [
              "--quiet"
              "-"
            ];
          };
          auto-format = true;
        }
      ];
    };
  };
}
