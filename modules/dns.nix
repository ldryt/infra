{ config, lib, ... }:
with lib;
{
  options = {
    ldryt-infra.dns.zone = mkOption {
      type = types.str;
      default = "ldryt.dev";
    };
    ldryt-infra.dns.records = mkOption {
      type = types.attrsOf types.str;
      default = { };
    };
  };
  config =
    let
      cfg = config.ldryt-infra.dns;
      dns = builtins.fromJSON (builtins.readFile ../dns.json);
      flatten = mapAttrs (
        zone: hosts: foldl' (acc: hostRecords: acc // hostRecords) { } (attrValues hosts)
      ) dns;
    in
    {
      ldryt-infra.dns.records = mapAttrs (_: subdomain: "${subdomain}.${cfg.zone}") flatten."${cfg.zone}";
    };
}
