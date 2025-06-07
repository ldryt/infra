locals {
  zone_id = "39509d1b1fb62e1c6623562d537b0bcb"
}

resource "cloudflare_dns_record" "root_A_record" {
  zone_id = local.zone_id
  name    = "@"
  content = hcloud_primary_ip.silvermist_ipv4.ip_address
  type    = "A"
  proxied = false
  ttl     = 60
}

resource "cloudflare_dns_record" "silvermist_subdomains" {
  for_each = local.dns.subdomains

  zone_id = local.zone_id
  name    = each.value
  content = hcloud_primary_ip.silvermist_ipv4.ip_address
  type    = "A"
  proxied = false
  ttl     = 60
}

resource "cloudflare_dns_record" "root_MX_record" {
  zone_id  = local.zone_id
  name     = "@"
  content  = "${local.dns.subdomains.mailserver}.${local.dns.zone}"
  type     = "MX"
  priority = 10
  ttl      = 60
}

resource "cloudflare_dns_record" "root_TXT_record__SPF" {
  zone_id = local.zone_id
  name    = "@"
  content = "\"v=spf1 a:${local.dns.subdomains.mailserver}.${local.dns.zone} -all\""
  type    = "TXT"
  ttl     = 60
}

resource "cloudflare_dns_record" "root_TXT_record__DMARC" {
  zone_id = local.zone_id
  name    = "_dmarc"
  content = "\"v=DMARC1; p=reject;\""
  type    = "TXT"
  ttl     = 60
}
