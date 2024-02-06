{ ... }: {
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    openFirewall = true;
  };
}
