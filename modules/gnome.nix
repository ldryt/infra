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
    cheese
    epiphany
    yelp
    file-roller
    geary
    seahorse
    gnome-font-viewer
    gnome-system-monitor
    gnome-characters
    gnome-contacts
    gnome-logs
    gnome-maps
    gnome-music
    gnome-photos
    gnome-tour
  ];
}
