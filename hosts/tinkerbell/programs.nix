{ pkgs, ... }:
{
  programs.nix-ld.enable = true;
  programs.bcc.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.gnome.gcr-ssh-agent.enable = false;
  security.pam.loginLimits = [
    {
      domain = "@users";
      item = "rtprio";
      type = "-";
      value = 1;
    }
  ];
  xdg.mime.defaultApplications = {
    "text/html" = "zen-beta.desktop";
    "application/xhtml+xml" = "zen-beta.desktop";
    "x-scheme-handler/http" = "zen-beta.desktop";
    "x-scheme-handler/https" = "zen-beta.desktop";
    "x-scheme-handler/about" = "zen-beta.desktop";
    "x-scheme-handler/unknown" = "zen-beta.desktop";
  };
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-curses
    screen
    vault
    bc
    bison
    coccinelle
    dtc
    dfu-util
    efitools
    flex
    gptfdisk
    graphviz
    imagemagick
    gnutls
    libguestfs
    ncurses
    subunit
    swig
    util-linux
    virtualenv
    rpi-imager
    typst
  ];
}
