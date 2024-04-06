{ pkgs, ... }:
{
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "10.0.0.0/32"
      "fe80::/10"
    ];
    extraPackages = [ pkgs.ipset ];
    banaction = "iptables-ipset-proto6-allports";
    maxretry = 1;
    bantime = "24h";
    bantime-increment = {
      enable = true;
      formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
      overalljails = true;
      rndtime = "4m";
    };
    jails = {
      "portscan".settings = {
        filter = "portscan";
        backend = "systemd";
      };
    };
  };

  environment.etc = {
    "fail2ban/filter.d/portscan.conf".text = ''
      [Definition]
      failregex = ^.*refused connection.* IN=.* SRC=<HOST>.*$
      journalmatch = _TRANSPORT=kernel
      ignoreregex =
    '';
  };
}
