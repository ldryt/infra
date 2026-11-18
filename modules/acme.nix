{ config, lib, ... }:
{
  systemd.services = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "acme-order-renew-${name}" {
      environment = {
        DESEC_POLLING_INTERVAL = lib.mkDefault "300";
        DESEC_PROPAGATION_TIMEOUT = lib.mkDefault "900";
      };
    }
  ) (lib.filterAttrs (_: cert: cert.dnsProvider == "desec") config.security.acme.certs);
}
