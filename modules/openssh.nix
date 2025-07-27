{ ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
    extraConfig = ''
      AllowTcpForwarding yes
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
  };

  # https://ghostty.org/docs/help/terminfo
  environment.enableAllTerminfo = true;
}
