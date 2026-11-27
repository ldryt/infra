{ lib, pkgs, ... }:
{
  home.file.".pi/agent/mcp.json".text = builtins.toJSON {
    mcpServers.playwright = {
      command = lib.getExe pkgs.playwright-mcp;
      args = [
        "--headless"
        "--isolated"
        "--sandbox"
        "--config"
        (pkgs.writeText "playwright-mcp-config.json" (builtins.toJSON {
          browser.launchOptions.chromiumSandbox = true;
        }))
        "--output-mode"
        "stdout"
      ];
      description = "Browse websites with a separate Chromium session: navigate, read pages, and interact with links and forms.";
      exposure = "deferred";
      toolExposure = {
        "*" = "hidden";
      }
      // lib.genAttrs [
        "browser_click"
        "browser_close"
        "browser_fill_form"
        "browser_hover"
        "browser_navigate"
        "browser_navigate_back"
        "browser_press_key"
        "browser_select_option"
        "browser_snapshot"
        "browser_tabs"
        "browser_take_screenshot"
        "browser_type"
        "browser_wait_for"
      ] (_: "deferred");
    };
  };
}
