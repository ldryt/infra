{ pkgs, ... }: {
  services.fail2ban = {
    enable = true;
    ignoreIP = [ "10.0.0.0/32" "fe80::/10" ];
    extraPackages = [ pkgs.ipset ];
    banaction = "iptables-ipset-proto6-allports";
    maxretry = 5;
    bantime = "10m";
    bantime-increment = {
      enable = true;
      formula =
        "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
      maxtime = "48h";
      overalljails = true;
      rndtime = "4m";
    };
    jails = {
      "portscan".settings = {
        filter = "portscan";
        backend = "systemd";
        findtime = 600;
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
