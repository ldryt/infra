locals {
  dns = jsondecode(file("${path.module}/dns.json"))
}

resource "gandi_livedns_record" "zarina_A_record" {
  name   = "zarina"
  zone   = local.dns.zone
  type   = "A"
  values = [hcloud_primary_ip.zarina_ipv4.ip_address]
  ttl    = 86400
}

resource "gandi_livedns_record" "zarina_subdomain" {
  for_each = local.dns.subdomains

  name   = each.value
  zone   = local.dns.zone
  type   = "CNAME"
  values = ["zarina"]
  ttl    = 86400
}
