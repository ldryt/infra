{ flakePackages, ... }:
{
  systemd.services.mcredir = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = "${flakePackages.mcredir}/bin/mcredir";
    };
  };
}
