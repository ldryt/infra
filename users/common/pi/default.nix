{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home.file.".pi/agent/extensions/pi-web-search".source = pkgs.fetchzip {
    url = "https://registry.npmjs.org/pi-web-search/-/pi-web-search-1.7.0.tgz";
    hash = "sha256-8HgICeK/HB07pLb+KRpB6kxIRW9Vc8s0VcJmtutuKr8=";
  };

  home.file.".pi/agent/mcp.json".text = builtins.toJSON {
    mcpServers = {
      playwright = import ./playwright.nix { inherit lib pkgs; };
    };
  };

  home.packages = [ inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
