{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home.file.".pi/agent/mcp.json".text = builtins.toJSON {
    mcpServers = {
      playwright = import ./playwright.nix { inherit lib pkgs; };
    };
  };

  home.packages = [ inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
