{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hashline
    ./notify.nix
    ./web-search
  ];

  home.sessionVariables.PI_OFFLINE = "1";

  home.file.".pi/agent/mcp.json".text = builtins.toJSON {
    mcpServers = {
      playwright = import ./playwright.nix { inherit lib pkgs; };
    };
  };

  home.packages = [ inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
