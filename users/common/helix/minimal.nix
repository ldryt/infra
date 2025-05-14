{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    settings = {
      theme = "base16_transparent";
      editor = {
        mouse = false;
        soft-wrap.enable = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        lsp.display-messages = true;
      };
    };
    extraPackages = with pkgs; [
      # Nix
      nil
      nixfmt-rfc-style

      # YAML
      yaml-language-server

      # TOML
      taplo-lsp
    ];
    languages.language = [
      {
        name = "c";
        file-types = [
          "c"
          "h"
        ];
        formatter.command = "clang-format";
        auto-format = true;
      }
      {
        name = "cpp";
        formatter.command = "clang-format";
        auto-format = true;
      }
      {
        name = "nix";
        formatter.command = "nixfmt";
        auto-format = true;
      }
    ];
  };
}
