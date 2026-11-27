{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./notify.nix
    ./web-search
  ];

  home.file.".pi/agent/AGENTS.md".text = ''
    Use Playwright to inspect or interact with pages, or when `web_search` is unavailable.
  '';

  home.file.".pi/agent/mcp.json".text = builtins.toJSON {
    mcpServers = {
      playwright = import ./playwright.nix { inherit lib pkgs; };
    };
  };

  home.packages = [ inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
