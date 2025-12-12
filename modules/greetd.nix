{ pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
                              --time \
                              --remember \
                              --remember-user-session \
                              --power-shutdown "/run/current-system/systemd/bin/systemctl poweroff" \
                              --power-reboot "/run/current-system/systemd/bin/systemctl reboot" \
                              --cmd sway'';
      };
    };
  };
}
