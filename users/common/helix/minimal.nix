{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    settings = {
      theme = "gruvbox";
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
    languages = [
      {
        name = "c";
        file-types = [ "c" "h" ];
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
