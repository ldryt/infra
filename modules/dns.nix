{ lib, ... }:
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
      dns = builtins.fromJSON (builtins.readFile ../dns.json);

      getServices = hosts: foldl' (acc: hostRecords: acc // hostRecords) { } (attrValues hosts);

      recordsByZone = mapAttrs (
        zoneName: hosts: mapAttrs (_: subdomain: "${subdomain}.${zoneName}") (getServices hosts)
      ) dns;

      allRecords = foldl' (acc: zoneRecords: acc // zoneRecords) { } (attrValues recordsByZone);
    in
    {
      ldryt-infra.dns.records = allRecords;
    };
}
