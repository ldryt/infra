resource "gandi_livedns_record" "zarina_A_record" {
  name   = "zarina"
  zone   = "ldryt.dev"
  type   = "A"
  values = [hcloud_primary_ip.zarina_ipv4.ip_address]
  ttl    = 86400
}

resource "gandi_livedns_record" "zarina_subdomain" {
  name   = "mc"
  zone   = "ldryt.dev"
  type   = "CNAME"
  values = ["zarina"]
  ttl    = 86400
}
