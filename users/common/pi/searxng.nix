{
  lib,
  pkgs,
  mcp-searxng,
  passwordFile,
}:
{
  command = lib.getExe mcp-searxng;
  env = {
    SEARXNG_URL = "https://search.ldryt.dev";
    AUTH_USERNAME = "pi";
    AUTH_PASSWORD = "!${lib.getExe' pkgs.coreutils "cat"} ${lib.escapeShellArg passwordFile}";
  };
  description = "Search the web for documentation, issues, and other public sources via SearXNG.";
  exposure = "deferred";
  toolExposure = {
    "*" = "hidden";
    searxng_web_search = "deferred";
  };
}
