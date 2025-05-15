{ pkgs, ... }:
{
  services.greetd = {
    enable = true;
    vt = 2;
    settings = {
      default_session = {
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
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
