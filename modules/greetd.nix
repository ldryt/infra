{ config, pkgs, ... }:
{
  ldryt-infra.persist.directories = [
    "/var/cache/tuigreet"
  ];
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
                              --time \
                              --remember \
                              --remember-user-session \
                              --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions \
                              --power-shutdown "/run/current-system/systemd/bin/systemctl poweroff" \
                              --power-reboot "/run/current-system/systemd/bin/systemctl reboot" \
                              --cmd sway'';
      };
    };
  };
}
