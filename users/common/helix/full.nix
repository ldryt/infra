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
        vscode-langservers-extracted
      ];
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
