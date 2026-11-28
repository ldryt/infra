{ config, lib, ... }:
{
  ldryt-infra.persist.directories = [
    "/var/lib/fail2ban"
  ];
  networking.nftables.enable = lib.mkDefault true;
  networking.firewall.logRefusedConnections = true;

  services.fail2ban = {
    enable = true;
    daemonSettings.Definition.logtarget = "STDOUT";
    ignoreIP = [
      "10.0.0.0/8"
      "127.0.0.0/8"
      "169.254.0.0/16"
      "172.16.0.0/12"
      "192.168.0.0/16"
      "FE80::/10"
      "::1/128"
      "82.65.203.15"
      "82.67.219.252"
      "49.12.97.63"
    ];
    banaction = config.services.fail2ban.banaction-allports;
    maxretry = 1;
    bantime = "8h";
    bantime-increment = {
      enable = true;
      formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
      overalljails = true;
      rndtime = "16h";
    };
    jails = {
      "portscan".settings = {
        filter = "portscan";
        backend = "systemd";
      };
      "sshd".settings = {
        mode = "aggressive";
        backend = "systemd";
      };
      "postfix".settings = {
        mode = "aggressive";
        backend = "systemd";
      };
    };
  };

  environment.etc."fail2ban/filter.d/portscan.conf".text = ''
    [Definition]
    failregex = ^.*refused connection: IN=.* SRC=<HOST>.* DPT=(?!(?:80|443|22000)(?:\s|$))\d+(?:\s|$)
    journalmatch = _TRANSPORT=kernel
  '';
}
