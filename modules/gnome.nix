{ pkgs, ... }: {

  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
  };

  environment.gnome.excludePackages = with pkgs.gnome; [
    cheese
    epiphany
    yelp
    file-roller
    geary
    seahorse
    gnome-characters
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    pkgs.gnome-photos
    gnome-system-monitor
    pkgs.gnome-connections
    pkgs.gnome-tour
  ];
}
