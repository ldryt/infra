{...}:
let
  dns = builtins.fromJSON (builtins.readFile ../dns.json);
in
{
  services.postfix = {
    enable = true;
    hostname = dns.zone;
    config = {
      inet_interfaces = "loopback-only";
    };
  };
}