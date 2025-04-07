{ ... }:
{
  imports = [
    ../../modules/sd-image-aarch64.nix

    ./networking.nix
    ./users.nix

    ./services/home-assistant.nix
    ./services/access-point.nix
    ./services/syncthing.nix

    ../../modules/backups.nix
    ../../modules/openssh.nix
    ../../modules/nix-settings.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/nix/sops_age_domus.key";

  boot.kernel.sysctl = {
    # Increase buffer sizes
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.core.rmem_default" = 16777216;
    "net.core.wmem_default" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";

    # Optimize TCP window scaling
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_adv_win_scale" = 1;

    # Enable TCP timestamps
    "net.ipv4.tcp_timestamps" = 1;

    # Enable Selective Acknowledgments (SACK)
    "net.ipv4.tcp_sack" = 1;

    # Increase the maximum number of connections
    "net.core.somaxconn" = 65535;
    "net.core.netdev_max_backlog" = 65535;
    "net.ipv4.tcp_max_syn_backlog" = 65535;

    # Enable TCP Fast Open
    "net.ipv4.tcp_fastopen" = 3;

    # Optimize congestion control
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Increase the local port range
    "net.ipv4.ip_local_port_range" = "1024 65535";

    # Disable TCP slow start after idle
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Enable TCP low latency
    "net.ipv4.tcp_low_latency" = 1;

    # Increase the size of the ARP cache
    "net.ipv4.neigh.default.gc_thresh1" = 1024;
    "net.ipv4.neigh.default.gc_thresh2" = 2048;
    "net.ipv4.neigh.default.gc_thresh3" = 4096;

    # Enable TCP MTU probing
    "net.ipv4.tcp_mtu_probing" = 1;

    # Disable TCP time wait
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_tw_recycle" = 1;

    # Increase the maximum number of SYN-ACK retries
    "net.ipv4.tcp_synack_retries" = 5;
  };

  services.journald.console = "/dev/tty1";

  systemd.services.disable-all-leds = {
    description = "Disable all LEDs on the system";
    wantedBy = [ "multi-user.target" ];
    script = ''
      echo none > /sys/class/leds/ACT/trigger
      echo none > /sys/class/leds/PWR/trigger
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

  system.stateVersion = "24.05";
}
