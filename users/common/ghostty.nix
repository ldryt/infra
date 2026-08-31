{ ... }:
{
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      theme = "dark:GitLab Dark,light:GitLab Light";
      window-theme = "system";
      gtk-titlebar = true;
      gtk-single-instance = true;
      confirm-close-surface = false;
      resize-overlay = "never";
      app-notifications = false;
    };
  };
}
