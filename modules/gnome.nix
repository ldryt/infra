{ pkgs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    epiphany
    gnome-console
  ];
  programs.nautilus-open-any-terminal.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings."com/github/stunkymonkey/nautilus-open-any-terminal".terminal = "ghostty";
      lockAll = false;
    }
  ];

  xdg.terminal-exec = {
    enable = true;
    settings.GNOME = [ "com.mitchellh.ghostty.desktop" ];
  };
  xdg.mime.defaultApplications = {
    "inode/directory" = "org.gnome.Nautilus.desktop";
    "application/pdf" = "org.gnome.Papers.desktop";
    "text/plain" = "org.gnome.TextEditor.desktop";
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/png" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
    "video/mp4" = "org.gnome.Showtime.desktop";
    "video/quicktime" = "org.gnome.Showtime.desktop";
    "video/x-matroska" = "org.gnome.Showtime.desktop";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ldryt-infra.persist.directories = [
    "/var/lib/AccountsService"
    {
      directory = "/var/lib/colord";
      user = "colord";
      group = "colord";
      mode = "0700";
    }
    {
      directory = "/var/lib/boltd";
      mode = "0700";
    }
  ];
}
