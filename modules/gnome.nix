{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
  };
  environment.gnome.excludePackages = with pkgs; [
    epiphany
    yelp
    seahorse
    gnome-font-viewer
    gnome-system-monitor
    gnome-characters
    gnome-logs
    gnome-maps
    gnome-music
    gnome-photos
    gnome-tour
  ];
}
