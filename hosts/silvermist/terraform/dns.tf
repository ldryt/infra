resource "gandi_livedns_record" "silvermist_A_record" {
  name   = "silvermist"
  zone   = local.dns.zone
  type   = "A"
  values = [hcloud_primary_ip.silvermist_ipv4.ip_address]
  ttl    = 86400
}

resource "gandi_livedns_record" "root_A_record" {
  name   = "@"
  zone   = local.dns.zone
  type   = "A"
  values = [hcloud_primary_ip.silvermist_ipv4.ip_address]
  ttl    = 86400
}

resource "gandi_livedns_record" "silvermist_subdomains" {
  for_each = local.dns.subdomains

  name   = each.value
  zone   = local.dns.zone
  type   = "CNAME"
  values = ["silvermist"]
  ttl    = 86400
}
