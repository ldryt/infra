{
  programs.i3status = {
    enable = true;
    enableDefault = false;
    general = {
      colors = false;
    };
    modules = {
      "time" = {
        position = 7;
        settings = {
          format = "%Y-%m-%d %H:%M";
        };
      };
      "memory" = {
        position = 6;
        settings = {
          format = "%free";
        };
      };
      "load" = {
        position = 5;
        settings = {
          format = "%5min";
        };
      };
      "disk /" = {
        position = 4;
        settings = {
          format = "%avail";
        };
      };
      "disk /nix" = {
        position = 3;
        settings = {
          format = "%avail";
        };
      };
      "battery all" = {
        position = 2;
        settings = {
          format = "%status %percentage";
          format_percentage = "%.f%s";
        };
      };
      "ethernet _first_" = {
        position = 1;
        settings = {
          format_up = "E: up";
          format_down = "E: down";
        };
      };
      "wireless _first_" = {
        position = 0;
        settings = {
          format_up = "W: %essid %quality";
          format_down = "W: down";
        };
      };
    };
  };
}
