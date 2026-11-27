{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  home.file.".pi/agent/mcp.json".text = builtins.toJSON {
    mcpServers = {
      playwright = import ./playwright.nix { inherit lib pkgs; };
      searxng = import ./searxng.nix {
        inherit lib pkgs;
        inherit (inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}) mcp-searxng;
        passwordFile = osConfig.sops.secrets."pi/searx/password".path;
      };
    };
  };

  home.packages = [ inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
