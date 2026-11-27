{ lib, pkgs }:
{
  command = lib.getExe pkgs.playwright-mcp;
  args = [
    "--headless"
    "--isolated"
    "--sandbox"
    "--config"
    (pkgs.writeText "playwright-mcp-config.json" (
      builtins.toJSON {
        browser.launchOptions.chromiumSandbox = true;
      }
    ))
    "--output-mode"
    "stdout"
  ];
  description = "Use Playwright to inspect or interact with pages. If `web_search` is unavailable, browse with Playwright, not Bash.";
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
}
