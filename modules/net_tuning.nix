{ ... }:
{
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    # Bufferbloat mitigations
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";

    # Time to wait (seconds) for FIN packet
    "net.ipv4.tcp_fin_timeout" = 15;

    # Low latency mode for TCP:
    "net.ipv4.tcp_low_latency" = 1;

    # Reduce TCP latency
    "net.ipv4.tcp_limit_output_bytes" = 131072;

    # TCP Fast Open (TFO)
    "net.ipv4.tcp_fastopen" = 1;

    # Ignore ICMP broadcasts to avoid participating in Smurf attacks
    "net.ipv4.icmp_echo_ignore_broadcasts" = 0;

    # Ignore bad ICMP errors
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

    # Do not accept ICMP redirects (prevent MITM attacks)
    "net.ipv4.conf.default.accept_redirects" = 1;
    "net.ipv4.conf.all.secure_redirects" = 1;
    "net.ipv4.conf.default.secure_redirects" = 1;

    # MTU discovery, only enable when ICMP blackhole detected
    "net.ipv4.tcp_mtu_probing" = 1;

    # Disable ICMP accept redirect
    "net.ipv4.conf.all.accept_redirects" = 0;

    # TCP SYN Flood Protection
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_max_syn_backlog" = 4096;

    # Protect against TCP time-wait assassination hazards
    "net.ipv4.tcp_rfc1337" = 1;
  };
}
